import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/frame_landmarks.dart';
import '../services/tflite_ai_service.dart';
import '../services/video_landmark_service.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/esenyas_app_bar.dart';
import '../widgets/hand_landmark_overlay.dart';

/// Testing Mode screen for evaluating gesture recognition accuracy.
///
/// Each "Next" cycle:
///   1. Picks a random expected gesture directly from the loaded model labels.
///   2. Runs a 4-second camera capture (same bounded-capture loop as the
///      main translation screen).
///   3. Runs TFLite inference on the captured buffer, measuring only the
///      preprocessing + inference time with a [Stopwatch].
///   4. Compares detected vs expected and updates session statistics.
class TestingModeScreen extends StatefulWidget {
  const TestingModeScreen({super.key});

  @override
  State<TestingModeScreen> createState() => _TestingModeScreenState();
}

class _TestingModeScreenState extends State<TestingModeScreen> {
  final _random = Random();

  // ── AI service ──
  final TFLiteAIService _aiService = TFLiteAIService();
  final VideoLandmarkService _videoLandmarkService = VideoLandmarkService();

  // ── Camera ──
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _permissionGranted = true;

  // ── Landmark buffer ──
  final List<FrameLandmarks> _frameBuffer = [];
  StreamSubscription<List<Hand>>? _landmarkSub;

  // ── Capture state ──
  bool _isCapturing = false;
  Timer? _captureTimer;

  // ── Test display state ──
  String _expectedGesture = '—';
  String _detectedGesture = '—';
  bool _isCorrect = false;
  String _inferenceTime = '0.00';
  int _testCount = 0;
  int _correctCount = 0;
  bool _saved = false;
  String _captureStatus = 'idle'; // idle | capturing | done

  // ── Golden self-test & Debug metrics ──
  bool _isRunningGoldenTest = false;
  GoldenResult? _goldenResult;
  int _latestHandCount = 0;
  final ValueNotifier<List<Hand>> _latestHands =
      ValueNotifier<List<Hand>>(const []);
  DateTime? _landmarkFpsWindowStart;
  int _landmarkFpsWindowCallbacks = 0;
  double _landmarkFps = 0;
  int _captureLandmarkCallbacks = 0;
  double _lastCaptureLandmarkFps = 0;
  Stopwatch? _captureStopwatch;
  int _sensorOrientation = 0;
  CameraLensDirection? _activeLensDirection;
  Timer? _debugTimer;

  // ── Uploaded video / Colab comparison ──
  bool _isAnalyzingVideo = false;
  String? _mediaFileName;
  String? _mediaPrediction;
  int _mediaConfidence = 0;
  VideoLandmarkResult? _mediaResult;
  List<MapEntry<String, double>> _mediaTop3 = const [];
  String? _mediaError;

  // ──────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initCameraAndService();
    if (kDebugMode) {
      _debugTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _debugTimer?.cancel();
    _captureTimer?.cancel();
    _captureStopwatch?.stop();
    _latestHands.dispose();
    _landmarkSub?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _aiService.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  // Initialisation
  // ──────────────────────────────────────────────────────────

  Future<void> _initCameraAndService() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _permissionGranted = false);
      return;
    }

    await _aiService.initialize();
    if (mounted && _aiService.labels.isNotEmpty) {
      setState(() => _expectedGesture = _aiService.labels.first);
    }
    _landmarkSub = _aiService.handPlugin.landmarkStream.listen(_onLandmarks);
    await _openCamera();
  }

  Future<void> _openCamera() async {
    final cameras = await availableCameras();
    final front = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await controller.initialize();
    await _startCameraStream(controller);

    if (mounted) {
      setState(() {
        _cameraController = controller;
        _cameraReady = true;
        _sensorOrientation = controller.description.sensorOrientation;
        _activeLensDirection = controller.description.lensDirection;
      });
    }
  }

  Future<void> _startCameraStream(CameraController controller) async {
    if (controller.value.isStreamingImages) return;
    await controller.startImageStream((CameraImage image) {
      _aiService.handPlugin.processFrame(
        image,
        controller.description.sensorOrientation,
      );
    });
  }

  // ──────────────────────────────────────────────────────────
  // Landmark callback
  // ──────────────────────────────────────────────────────────

  void _onLandmarks(List<Hand> hands) {
    _latestHandCount = hands.length;
    _latestHands.value = List<Hand>.unmodifiable(hands);

    final now = DateTime.now();
    _landmarkFpsWindowStart ??= now;
    _landmarkFpsWindowCallbacks++;
    final fpsElapsedMs =
        now.difference(_landmarkFpsWindowStart!).inMilliseconds;
    if (fpsElapsedMs >= 1000) {
      _landmarkFps =
          _landmarkFpsWindowCallbacks * 1000.0 / fpsElapsedMs;
      _landmarkFpsWindowStart = now;
      _landmarkFpsWindowCallbacks = 0;
    }

    if (!_isCapturing) return;
    _captureLandmarkCallbacks++;

    if (hands.isEmpty) {
      _frameBuffer.add(const FrameLandmarks.noHand());
    } else {
      // Match Colab: model input stays in raw MediaPipe camera/sensor space.
      // The skeleton overlay handles portrait rotation separately.
      final rawHands = hands.map((hand) {
        return hand.landmarks
            .map((lm) => <double>[lm.x, lm.y, lm.z])
            .toList();
      }).toList();
      _frameBuffer.add(FrameLandmarks(handDetected: true, hands: rawHands));
    }
  }

  // ──────────────────────────────────────────────────────────
  // Button handlers
  // ──────────────────────────────────────────────────────────

  void _handleNextGesture() {
    if (_isCapturing || !_cameraReady) return;

    final modelLabels = _aiService.labels;
    if (modelLabels.isEmpty) return;
    final idx = _random.nextInt(modelLabels.length);

    setState(() {
      _expectedGesture = modelLabels[idx];
      _detectedGesture = '—';
      _isCorrect = false;
      _inferenceTime = '0.00';
      _isCapturing = true;
      _saved = false;
      _captureStatus = 'capturing';
      _testCount++;
    });

    _frameBuffer.clear();
    _captureLandmarkCallbacks = 0;
    _lastCaptureLandmarkFps = 0;
    _captureStopwatch?.stop();
    _captureStopwatch = Stopwatch()..start();
    _captureTimer = Timer(const Duration(seconds: 4), _onCaptureComplete);
  }

  Future<void> _onCaptureComplete() async {
    if (!mounted) return;

    // Freeze the bounded capture before inference so late landmark callbacks
    // cannot change the debug metrics or buffer for this test cycle.
    _isCapturing = false;
    _captureStopwatch?.stop();
    final captureElapsedMs = _captureStopwatch?.elapsedMilliseconds ?? 0;
    _lastCaptureLandmarkFps = captureElapsedMs > 0
        ? _captureLandmarkCallbacks * 1000.0 / captureElapsedMs
        : 0;
    final buffer = List<FrameLandmarks>.from(_frameBuffer);

    // Measure only preprocessing + inference, not the 4-second capture.
    final sw = Stopwatch()..start();
    final result = await _aiService.recognizeFromBuffer(buffer);
    sw.stop();

    if (!mounted) return;

    final detected = result?.sign ?? '(hindi natukoy)';
    final correct = detected == _expectedGesture;
    if (correct) setState(() => _correctCount++);

    setState(() {
      _detectedGesture = detected;
      _isCorrect = correct;
      _inferenceTime = (sw.elapsedMilliseconds / 1000).toStringAsFixed(3);
      _isCapturing = false;
      _captureStatus = 'done';
    });
  }

  void _handleRecordTest() {
    if (_captureStatus != 'done') return;
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  Future<void> _handleUploadVideo() async {
    if (_isAnalyzingVideo || _isCapturing) return;

    final file = await FilePicker.pickFile(
      type: FileType.video,
    );
    if (file == null) return;
    final path = file.path;
    if (path == null || path.isEmpty) {
      setState(() {
        _mediaFileName = file.name;
        _mediaError = 'Hindi ma-access ang local path ng napiling video.';
      });
      return;
    }

    setState(() {
      _isAnalyzingVideo = true;
      _mediaFileName = file.name;
      _mediaPrediction = null;
      _mediaConfidence = 0;
      _mediaResult = null;
      _mediaTop3 = const [];
      _mediaError = null;
    });

    final controller = _cameraController;
    final restartCamera =
        controller != null && controller.value.isStreamingImages;

    try {
      if (restartCamera && controller != null) {
        await controller.stopImageStream();
      }

      final videoResult = await _videoLandmarkService.analyzeVideo(path);
      final prediction =
          await _aiService.recognizeFromBuffer(videoResult.frames);
      final top3 = List<MapEntry<String, double>>.from(_aiService.lastTop3);

      if (!mounted) return;
      setState(() {
        _mediaResult = videoResult;
        _mediaPrediction = prediction?.sign ?? '(hindi natukoy)';
        _mediaConfidence = prediction?.confidence ?? 0;
        _mediaTop3 = top3;
        _isAnalyzingVideo = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _mediaError = e.message ?? e.code;
        _isAnalyzingVideo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mediaError = e.toString();
        _isAnalyzingVideo = false;
      });
    } finally {
      if (restartCamera &&
          mounted &&
          controller != null &&
          controller.value.isInitialized &&
          !controller.value.isStreamingImages) {
        try {
          await _startCameraStream(controller);
        } catch (_) {
          // Keep the video result visible even if camera restart fails.
        }
      }
    }
  }

  Future<void> _handleRunGoldenSelfTest() async {
    if (_isRunningGoldenTest) return;
    setState(() => _isRunningGoldenTest = true);
    try {
      final result = await _aiService.runGoldenSelfTest();
      if (mounted) {
        setState(() {
          _goldenResult = result;
          _isRunningGoldenTest = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _goldenResult = GoldenResult(
            passed: false,
            seqDiff: 1.0,
            probDiff: 1.0,
            topLabel: 'ERROR',
            expectedTop: 'UNKNOWN',
            topMatches: false,
            error: e.toString(),
          );
          _isRunningGoldenTest = false;
        });
      }
    }
  }

  int get _accuracy =>
      _testCount > 0 ? (_correctCount / _testCount * 100).round() : 0;

  String get _lastActiveRange {
    final first = _aiService.lastFirstActive;
    final last = _aiService.lastLastActive;
    return first >= 0 && last >= 0 ? '$first..$last' : 'none';
  }

  // ──────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ESenyasAppBar(title: 'Testing Mode'),
            Expanded(
              child: Container(
                color: Colors.white,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Research banner
                      Container(
                        color: ESenyasColors.gray800,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.science,
                                size: 18, color: ESenyasColors.accentGreen),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Research Data Collection',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Test #$_testCount · ${_isCapturing ? "Kumukuha (4s)..." : "Handa"}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: ESenyasColors.gray400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Camera preview
                            _buildCameraSection(),
                            const SizedBox(height: 12),

                            // Detection status
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _isCapturing
                                        ? const Color(0xFFFACC15)
                                        : ESenyasColors.accentGreen,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isCapturing
                                      ? 'Kumukuha ng 4-segundo na clip...'
                                      : 'Kamay ay Handa',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: ESenyasColors.gray600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Expected vs Detected
                            Row(
                              children: [
                                Expanded(
                                  child: _ComparisonBox(
                                    label: 'Expected',
                                    value: _expectedGesture,
                                    bgColor: ESenyasColors.surfaceBlueLight,
                                    borderColor: ESenyasColors.primaryBlue,
                                    textColor: ESenyasColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _ComparisonBox(
                                    label: 'Detected',
                                    value: _detectedGesture,
                                    bgColor: _captureStatus == 'done'
                                        ? (_isCorrect
                                            ? const Color(0xFFF0FDF4)
                                            : const Color(0xFFFEF2F2))
                                        : const Color(0xFFF9FAFB),
                                    borderColor: _captureStatus == 'done'
                                        ? (_isCorrect
                                            ? ESenyasColors.accentGreen
                                            : const Color(0xFFF87171))
                                        : ESenyasColors.gray300,
                                    textColor: _captureStatus == 'done'
                                        ? (_isCorrect
                                            ? ESenyasColors.accentGreen
                                            : const Color(0xFFDC2626))
                                        : ESenyasColors.gray500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Result pills
                            const Text(
                              'Result',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: ESenyasColors.gray700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: _ResultPill(
                                    label: 'Correct',
                                    icon: Icons.check,
                                    active: _captureStatus == 'done' &&
                                        _isCorrect,
                                    activeColor: ESenyasColors.accentGreen,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _ResultPill(
                                    label: 'Incorrect',
                                    icon: Icons.close,
                                    active: _captureStatus == 'done' &&
                                        !_isCorrect,
                                    activeColor: ESenyasColors.destructiveRed,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Inference time (real Stopwatch measurement)
                            const Text(
                              'Inference Time',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: ESenyasColors.gray700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 56,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                border: Border.all(
                                    color: const Color(0xFFE5E7EB), width: 2),
                                borderRadius: BorderRadius.circular(
                                    ESenyasDimens.borderRadiusMd),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    _inferenceTime,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: ESenyasColors.gray800,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    's',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: ESenyasColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Session stats
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    ESenyasColors.primaryBlue,
                                    ESenyasColors.accentGreen,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                    ESenyasDimens.borderRadiusMd),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Session Statistics',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _StatItem(
                                          value: '$_testCount',
                                          label: 'Tests'),
                                      _StatItem(
                                          value: '$_correctCount',
                                          label: 'Correct'),
                                      _StatItem(
                                          value: '$_accuracy%',
                                          label: 'Accuracy'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: ESenyasDimens.buttonHeight,
                                    child: ElevatedButton.icon(
                                      onPressed: _captureStatus == 'done'
                                          ? _handleRecordTest
                                          : null,
                                      icon: const Icon(Icons.save, size: 18),
                                      label: Text(
                                          _saved ? 'Saved!' : 'Record Test'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _saved
                                            ? ESenyasColors.accentGreen
                                            : ESenyasColors.primaryBlue,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor:
                                            ESenyasColors.gray300,
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              ESenyasDimens.borderRadiusMd),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SizedBox(
                                    height: ESenyasDimens.buttonHeight,
                                    child: ElevatedButton.icon(
                                      onPressed: _isCapturing || !_cameraReady
                                          ? null
                                          : _handleNextGesture,
                                      icon: const Icon(Icons.skip_next,
                                          size: 18),
                                      label: Text(_isCapturing
                                          ? 'Kumukuha...'
                                          : 'Next'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            ESenyasColors.accentGreen,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor:
                                            ESenyasColors.gray300,
                                        elevation: 1,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              ESenyasDimens.borderRadiusMd),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // ── Uploaded video test ──
                            SizedBox(
                              width: double.infinity,
                              height: ESenyasDimens.buttonHeight,
                              child: OutlinedButton.icon(
                                onPressed: _isAnalyzingVideo || _isCapturing
                                    ? null
                                    : _handleUploadVideo,
                                icon: _isAnalyzingVideo
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.video_file_outlined,
                                        size: 18),
                                label: Text(
                                  _isAnalyzingVideo
                                      ? 'Analyzing video...'
                                      : 'Upload test video',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ESenyasColors.primaryBlue,
                                  side: const BorderSide(
                                    color: ESenyasColors.primaryBlue,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      ESenyasDimens.borderRadiusMd,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_mediaFileName != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(
                                    ESenyasDimens.borderRadiusMd,
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFCBD5E1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _mediaFileName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: ESenyasColors.gray800,
                                      ),
                                    ),
                                    if (_mediaError != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Error: $_mediaError',
                                        style: const TextStyle(
                                          color: ESenyasColors.destructiveRed,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ] else if (_mediaResult != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'Prediction: ${_mediaPrediction ?? "—"}'
                                        '${_mediaConfidence > 0 ? " · $_mediaConfidence%" : ""}\n'
                                        'Source: ${_mediaResult!.sourceFps.toStringAsFixed(2)} fps · '
                                        '${(_mediaResult!.durationMs / 1000).toStringAsFixed(2)} s\n'
                                        'Frames: ${_mediaResult!.sampledFrames} · '
                                        'Active: ${_mediaResult!.activeFrames}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          height: 1.45,
                                          fontFamily: 'monospace',
                                          color: ESenyasColors.gray700,
                                        ),
                                      ),
                                      if (_mediaTop3.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        const Text(
                                          'Top 3',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: ESenyasColors.gray700,
                                          ),
                                        ),
                                        ..._mediaTop3.map(
                                          (entry) => Text(
                                            '• ${entry.key}: '
                                            '${(entry.value * 100).toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'monospace',
                                              color: ESenyasColors.gray700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),

                            // ── Run golden self-test button ──
                            SizedBox(
                              width: double.infinity,
                              height: ESenyasDimens.buttonHeight,
                              child: ElevatedButton.icon(
                                onPressed: _isRunningGoldenTest
                                    ? null
                                    : _handleRunGoldenSelfTest,
                                icon: _isRunningGoldenTest
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.verified, size: 18),
                                label: Text(_isRunningGoldenTest
                                    ? 'Running self-test...'
                                    : 'Run golden self-test'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ESenyasColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      ESenyasColors.gray300,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        ESenyasDimens.borderRadiusMd),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            // ── Golden self-test result ──
                            if (_goldenResult != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _goldenResult!.passed
                                      ? const Color(0xFFF0FDF4)
                                      : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(
                                      ESenyasDimens.borderRadiusMd),
                                  border: Border.all(
                                    color: _goldenResult!.passed
                                        ? ESenyasColors.accentGreen
                                        : const Color(0xFFF87171),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _goldenResult!.passed
                                              ? 'PASS (Golden Self-Test)'
                                              : 'FAIL (Golden Self-Test)',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _goldenResult!.passed
                                                ? ESenyasColors.accentGreen
                                                : const Color(0xFFDC2626),
                                          ),
                                        ),
                                        Icon(
                                          _goldenResult!.passed
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 18,
                                          color: _goldenResult!.passed
                                              ? ESenyasColors.accentGreen
                                              : const Color(0xFFDC2626),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'seqDiff: ${_goldenResult!.seqDiff.toStringAsExponential(3)} (expected < 1e-4)\n'
                                      'probDiff: ${_goldenResult!.probDiff.toStringAsExponential(3)} (expected < 1e-3)\n'
                                      'Top label: "${_goldenResult!.topLabel}"',
                                      style: TextStyle(
                                        fontSize: 11,
                                        height: 1.4,
                                        fontFamily: 'monospace',
                                        color: _goldenResult!.passed
                                            ? const Color(0xFF166534)
                                            : const Color(0xFF991B1B),
                                      ),
                                    ),
                                    if (_goldenResult!.error != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Error: ${_goldenResult!.error}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF991B1B),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            // ── Debug overlay (kDebugMode only) ──
                            if (kDebugMode) ...[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(
                                      ESenyasDimens.borderRadiusMd),
                                  border: Border.all(
                                      color: const Color(0xFF334155)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.bug_report,
                                            size: 14,
                                            color: Color(0xFF38BDF8)),
                                        SizedBox(width: 6),
                                        Text(
                                          'Debug Overlay (kDebugMode)',
                                          style: TextStyle(
                                            color: Color(0xFF38BDF8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Hands in latest frame: $_latestHandCount\n'
                                      'Live landmark FPS: ${_landmarkFps.toStringAsFixed(1)}\n'
                                      'Frames buffered: ${_frameBuffer.length}\n'
                                      'Capture callbacks: $_captureLandmarkCallbacks\n'
                                      'Last capture FPS: ${_lastCaptureLandmarkFps.toStringAsFixed(1)}\n'
                                      'Sensor orientation: $_sensorOrientation°\n'
                                      'Lens: ${_activeLensDirection?.name ?? "unknown"}\n'
                                      'lastBufferFrames: ${_aiService.lastBufferFrames}\n'
                                      'lastActiveFrames: ${_aiService.lastActiveFrames}\n'
                                      'activeRange: $_lastActiveRange\n'
                                      'mirrorInputX (model): ${TFLiteAIService.mirrorInputX}\n'
                                      'lastTop3:',
                                      style: const TextStyle(
                                        color: Color(0xFFE2E8F0),
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (_aiService.lastTop3.isEmpty)
                                      const Text(
                                        '  (none yet)',
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                        ),
                                      )
                                    else
                                      ..._aiService.lastTop3.map(
                                        (entry) => Text(
                                          '  • ${entry.key}: ${(entry.value * 100).toStringAsFixed(1)}% (${entry.value.toStringAsFixed(4)})',
                                          style: const TextStyle(
                                            color: Color(0xFFFDE047),
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const ESenyasBottomNavBar(currentIndex: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    if (!_permissionGranted) {
      return Container(
        height: 200,
        width: double.infinity,
        color: ESenyasColors.gray800,
        child: const Center(
          child: Text(
            'Pahintulot sa Camera na kailangan.',
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
      );
    }

    if (!_cameraReady || _cameraController == null) {
      return Container(
        height: 200,
        width: double.infinity,
        color: ESenyasColors.gray800,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white54),
        ),
      );
    }

    final previewSize = _cameraController!.value.previewSize!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(ESenyasDimens.borderRadiusMd),
      child: Stack(
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: previewSize.height,
                    height: previewSize.width,
                    child: _activeLensDirection == CameraLensDirection.front
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.diagonal3Values(-1, 1, 1),
                            child: CameraPreview(_cameraController!),
                          )
                        : CameraPreview(_cameraController!),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ValueListenableBuilder<List<Hand>>(
              valueListenable: _latestHands,
              builder: (context, hands, _) {
                final overlay = HandLandmarkOverlay(
                  hands: hands,
                  previewSize: previewSize,
                  lensDirection:
                      _activeLensDirection ?? CameraLensDirection.front,
                  sensorOrientation: _sensorOrientation,
                );
                return _activeLensDirection == CameraLensDirection.front
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.diagonal3Values(-1, 1, 1),
                        child: overlay,
                      )
                    : overlay;
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: ValueListenableBuilder<List<Hand>>(
              valueListenable: _latestHands,
              builder: (context, hands, _) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Hands: ${hands.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          if (_isCapturing)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ESenyasColors.destructiveRed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'REC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Private UI widgets (visual style unchanged from original)
// ──────────────────────────────────────────────────────────────

class _ComparisonBox extends StatelessWidget {
  final String label;
  final String value;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _ComparisonBox({
    required this.label,
    required this.value,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: ESenyasColors.gray700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius:
                BorderRadius.circular(ESenyasDimens.borderRadiusMd),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;

  const _ResultPill({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ESenyasDimens.buttonHeight,
      decoration: BoxDecoration(
        color: active ? activeColor : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(ESenyasDimens.borderRadiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 18,
              color: active ? Colors.white : ESenyasColors.gray300),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: active ? Colors.white : ESenyasColors.gray300,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
