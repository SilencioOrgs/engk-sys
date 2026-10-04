// Retain the uploaded-video path's existing explicit camera null guards.
// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/detected_sign.dart';
import '../models/frame_landmarks.dart';
import '../providers/app_provider.dart';
import '../services/tflite_ai_service.dart';
import '../services/video_landmark_service.dart';
import '../utils/constants.dart';
import '../utils/live_landmark_transform.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/esenyas_app_bar.dart';
import '../widgets/hand_landmark_overlay.dart';
import '../widgets/sign_capture_animation.dart';

enum SignPhase { idle, signing, analyzing }

/// Gesture translation screen — the primary application feature.
///
/// Recognition collects six-second windows from the live landmark stream.
/// Only model input is transformed; the skeleton keeps raw sensor landmarks.

class GestureTranslationScreen extends StatefulWidget {
  const GestureTranslationScreen({super.key});

  @override
  State<GestureTranslationScreen> createState() =>
      _GestureTranslationScreenState();
}

class _GestureTranslationScreenState
    extends State<GestureTranslationScreen> {
  // ── AI service ──
  final TFLiteAIService _aiService = TFLiteAIService();
  final VideoLandmarkService _videoLandmarkService = VideoLandmarkService();

  // ── Camera ──
  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _permissionGranted = true; // optimistic until runtime check
  CameraLensDirection _lensDirection = CameraLensDirection.front;
  int _sensorOrientation = 0;
  Size _rawFrameSize = Size.zero;

  // ── Dynamic camera frame height ──
  static const double _cameraHeightMin = 140.0;
  static const double _cameraHeightMax = 400.0;
  double _cameraHeight = ESenyasDimens.cameraPreviewHeight;

  // ── Live landmarks ──
  StreamSubscription<List<Hand>>? _landmarkSub;
  final ValueNotifier<List<Hand>> _latestHands =
      ValueNotifier<List<Hand>>(const []);

  // Sign and analyze cycle.
  bool _isDetecting = false;
  SignPhase _phase = SignPhase.idle;
  final List<FrameLandmarks> _frameBuffer = [];
  Timer? _captureTimer;
  Timer? _analysisTimer;
  Timer? _nextSignTimer;
  int _cycleGeneration = 0;
  bool _showRetryMessage = false;
  static const Duration _signDuration = Duration(seconds: 6);
  static const Duration _minimumAnalysisDuration = Duration(milliseconds: 1200);

  String _currentSign = '';
  int _currentConfidence = 0;

  // ── Sentence / session ──
  String _sentence = '';
  final List<DetectedSign> _sessionSigns = [];
  bool _savedToast = false;

  // ── Uploaded-video test state ──
  bool _isAnalyzingVideo = false;
  String? _uploadedVideoName;
  String? _uploadedVideoPrediction;
  int _uploadedVideoConfidence = 0;
  List<MapEntry<String, double>> _uploadedVideoTop3 = const [];
  VideoLandmarkResult? _uploadedVideoResult;
  String? _uploadedVideoError;

  // ── Feedback (thumbs up / down) ──
  /// null = no feedback given yet, true = thumbs up, false = thumbs down
  bool? _feedbackValue;
  bool _feedbackSubmitted = false;

  // ──────────────────────────────────────────────────────────
  // Lifecycle
  // ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initCameraAndService();
  }

  @override
  void dispose() {
    _cancelCycleTimers();
    _cycleGeneration++;
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
    // 1. Request CAMERA permission.
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _permissionGranted = false);
      return;
    }

    // 2. Load TFLite model + set up hand_landmarker plugin.
    await _aiService.initialize();

    // 3. Subscribe to the landmark stream BEFORE starting the image stream
    //    so no frames are lost.
    _landmarkSub = _aiService.handPlugin.landmarkStream.listen(_onLandmarks);

    // 4. Open the front camera.
    await _openCamera(_lensDirection);
  }

  Future<void> _openCamera(CameraLensDirection direction) async {
    final cameras = await availableCameras();
    final desc = cameras.firstWhere(
      (c) => c.lensDirection == direction,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      desc,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await controller.initialize();

    _sensorOrientation = controller.description.sensorOrientation;

    // Feed every camera frame to the hand landmarker (fire-and-forget).
    await _startCameraStream(controller);

    if (mounted) {
      setState(() {
        _cameraController = controller;
        _cameraReady = true;
        _lensDirection = direction;
        _sensorOrientation = controller.description.sensorOrientation;
      });
    }
  }

  Future<void> _startCameraStream(CameraController controller) async {
    if (controller.value.isStreamingImages) return;
    await controller.startImageStream((CameraImage image) {
      _rawFrameSize = Size(image.width.toDouble(), image.height.toDouble());
      _aiService.handPlugin.processFrame(
        image,
        controller.description.sensorOrientation,
      );
    });
  }

  // ──────────────────────────────────────────────────────────
  // Landmark stream callback
  // ──────────────────────────────────────────────────────────

  void _onLandmarks(List<Hand> hands) {
    if (!mounted) return;
    _latestHands.value = List<Hand>.unmodifiable(hands);
    if (!_isDetecting || _phase != SignPhase.signing) return;

    _frameBuffer.add(
      hands.isEmpty
          ? const FrameLandmarks.noHand()
          : FrameLandmarks(
              handDetected: true,
              hands: LiveLandmarkTransform.toTrainingSpace(
                hands,
                sensorOrientation: _sensorOrientation,
                rawFrameSize: _rawFrameSize,
              ),
            ),
    );
  }

  void _cancelCycleTimers() {
    _captureTimer?.cancel();
    _analysisTimer?.cancel();
    _nextSignTimer?.cancel();
    _captureTimer = null;
    _analysisTimer = null;
    _nextSignTimer = null;
  }

  bool _isCurrentCycle(int generation) =>
      mounted && _isDetecting && generation == _cycleGeneration;

  void _beginSigningWindow() {
    if (!mounted || !_isDetecting) return;
    _cancelCycleTimers();
    _frameBuffer.clear();
    setState(() {
      _phase = SignPhase.signing;
      _showRetryMessage = false;
    });
    _captureTimer = Timer(_signDuration, _finishSigningWindow);
  }

  Future<void> _finishSigningWindow() async {
    if (!mounted || !_isDetecting || _phase != SignPhase.signing) return;
    _captureTimer?.cancel();
    _captureTimer = null;
    final generation = _cycleGeneration;
    final snapshot = List<FrameLandmarks>.from(_frameBuffer);
    setState(() => _phase = SignPhase.analyzing);
    final stopwatch = Stopwatch()..start();
    DetectedSign? result;
    try {
      // Paint the loading state before synchronous TFLite inference begins.
      await WidgetsBinding.instance.endOfFrame;
      if (!_isCurrentCycle(generation)) return;
      result = await _aiService.recognizeFromBuffer(snapshot);
    } catch (e) {
      debugPrint('Live landmark analysis failed: $e');
    }
    stopwatch.stop();
    if (!_isCurrentCycle(generation)) return;

    final remaining = _minimumAnalysisDuration - stopwatch.elapsed;
    _analysisTimer = Timer(
      remaining.isNegative ? Duration.zero : remaining,
      () => _completeSigningAnalysis(result, generation),
    );
  }

  void _completeSigningAnalysis(DetectedSign? result, int generation) {
    if (!_isCurrentCycle(generation)) return;
    _analysisTimer = null;
    if (result != null) {
      setState(() {
        _currentSign = result.sign;
        _currentConfidence = result.confidence;
        _sentence = _sentence.isEmpty
            ? result.sign
            : '$_sentence ${result.sign}';
        _sessionSigns.add(result);
      });
      _scheduleNextSigningWindow(generation);
    } else {
      setState(() => _showRetryMessage = true);
      _analysisTimer = Timer(const Duration(milliseconds: 1500), () {
        if (!_isCurrentCycle(generation)) return;
        _analysisTimer = null;
        setState(() => _showRetryMessage = false);
        _scheduleNextSigningWindow(generation);
      });
    }
  }

  void _scheduleNextSigningWindow(int generation) {
    if (!_isCurrentCycle(generation)) return;
    _nextSignTimer = Timer(const Duration(milliseconds: 400), () {
      if (_isCurrentCycle(generation)) _beginSigningWindow();
    });
  }

  // Button handlers.
  void _handleStart() {
    if (!_cameraReady || _isDetecting || _isAnalyzingVideo) return;
    _cycleGeneration++;
    setState(() {
      _sentence = '';
      _currentSign = '';
      _currentConfidence = 0;
      _feedbackValue = null;
      _feedbackSubmitted = false;
      _isDetecting = true;
    });
    _sessionSigns.clear();
    _beginSigningWindow();
  }

  void _handleStop() {
    _cancelCycleTimers();
    _cycleGeneration++;
    _frameBuffer.clear();
    setState(() {
      _isDetecting = false;
      _phase = SignPhase.idle;
      _showRetryMessage = false;
    });
  }

  void _handleClear() {
    setState(() {
      _sentence = '';
      _currentSign = '';
      _currentConfidence = 0;
      _feedbackValue = null;
      _feedbackSubmitted = false;
    });
    _sessionSigns.clear();
  }

  void _handleSave() {
    if (_sessionSigns.isEmpty) return;
    context.read<AppProvider>().addHistoryItem(
          translatedSentence: _sentence,
          detectedSigns: List.from(_sessionSigns),
        );
    setState(() => _savedToast = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _savedToast = false);
    });
  }

  Future<void> _handleUploadVideo() async {
    if (_isAnalyzingVideo || _isDetecting) return;

    final file = await FilePicker.pickFile(type: FileType.video);
    if (file == null) return;

    final path = file.path;
    if (path == null || path.isEmpty) {
      setState(() {
        _uploadedVideoName = file.name;
        _uploadedVideoError =
            'Hindi ma-access ang local path ng napiling video.';
      });
      return;
    }

    setState(() {
      _isAnalyzingVideo = true;
      _uploadedVideoName = file.name;
      _uploadedVideoPrediction = null;
      _uploadedVideoConfidence = 0;
      _uploadedVideoTop3 = const [];
      _uploadedVideoResult = null;
      _uploadedVideoError = null;
    });

    final controller = _cameraController;
    final restartCamera =
        controller != null && controller.value.isStreamingImages;

    try {
      if (restartCamera && controller != null) {
        await controller.stopImageStream();
      }

      final analyzed = await _videoLandmarkService.analyzeVideo(path);
      final prediction = await _aiService.recognizeFromBuffer(analyzed.frames);
      final top3 = List<MapEntry<String, double>>.from(_aiService.lastTop3);

      if (!mounted) return;
      setState(() {
        _uploadedVideoResult = analyzed;
        _uploadedVideoPrediction =
            prediction?.sign ?? '(hindi natukoy)';
        _uploadedVideoConfidence = prediction?.confidence ?? 0;
        _uploadedVideoTop3 = top3;
        _isAnalyzingVideo = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadedVideoError = e.message ?? e.code;
        _isAnalyzingVideo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadedVideoError = e.toString();
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
          // Keep the uploaded-video result visible even if camera restart fails.
        }
      }
    }
  }

  Future<void> _handleFlipCamera() async {
    if (!_cameraReady || _isDetecting) return;
    final next = _lensDirection == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;
    setState(() => _cameraReady = false);
    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _cameraController = null;
    await _openCamera(next);
  }

  bool get _canSave => !_isDetecting && _sessionSigns.isNotEmpty;
  bool get _canClear => !_isDetecting && _sentence.isNotEmpty;

  void _handleFeedback(bool isPositive) {
    setState(() {
      _feedbackValue = isPositive;
      _feedbackSubmitted = true;
    });
    // Auto-dismiss the "thank you" after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _feedbackSubmitted = false);
    });
  }

  // ──────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<AppProvider>().darkMode;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ESenyasAppBar(title: 'Pagsasalin ng Senyas'),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    color: darkMode
                        ? ESenyasColors.backgroundDark
                        : Colors.white,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // ── Camera preview (dynamic height) ──
                          _buildCameraSection(darkMode),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: ESenyasDimens.buttonHeight,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _isAnalyzingVideo || _isDetecting
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
                                        : const Icon(
                                            Icons.video_file_outlined,
                                            size: 18,
                                          ),
                                    label: Text(
                                      _isAnalyzingVideo
                                          ? 'Sinusuri ang video...'
                                          : 'Mag-upload ng Test Video',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor:
                                          ESenyasColors.primaryBlue,
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
                                if (_uploadedVideoName != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: darkMode
                                          ? ESenyasColors.cardDark
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(
                                        ESenyasDimens.borderRadiusMd,
                                      ),
                                      border: Border.all(
                                        color: darkMode
                                            ? ESenyasColors.gray700
                                            : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _uploadedVideoName!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: darkMode
                                                ? Colors.white
                                                : ESenyasColors.gray800,
                                          ),
                                        ),
                                        if (_uploadedVideoError != null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Error: $_uploadedVideoError',
                                            style: const TextStyle(
                                              color:
                                                  ESenyasColors.destructiveRed,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ] else if (_uploadedVideoResult !=
                                            null) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Prediction: ${_uploadedVideoPrediction ?? "—"}'
                                            '${_uploadedVideoConfidence > 0 ? " · $_uploadedVideoConfidence%" : ""}\n'
                                            'Source: ${_uploadedVideoResult!.sourceFps.toStringAsFixed(2)} fps · '
                                            '${(_uploadedVideoResult!.durationMs / 1000).toStringAsFixed(2)} s\n'
                                            'Frames: ${_uploadedVideoResult!.sampledFrames} · '
                                            'Active: ${_uploadedVideoResult!.activeFrames}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              height: 1.45,
                                              fontFamily: 'monospace',
                                              color: darkMode
                                                  ? ESenyasColors.gray300
                                                  : ESenyasColors.gray700,
                                            ),
                                          ),
                                          if (_uploadedVideoTop3.isNotEmpty)
                                            ..._uploadedVideoTop3.map(
                                              (entry) => Text(
                                                '• ${entry.key}: '
                                                '${(entry.value * 100).toStringAsFixed(1)}%',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: 'monospace',
                                                  color: darkMode
                                                      ? ESenyasColors.gray300
                                                      : ESenyasColors.gray700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Detection status pill
                                _DetectionStatusPill(
                                  status: _phase == SignPhase.idle && _currentSign.isNotEmpty
                                      ? 'detected'
                                      : _phase.name,
                                  currentSign: _currentSign,
                                  confidence: _currentConfidence,
                                  darkMode: darkMode,
                                  statusText: _showRetryMessage
                                      ? 'Hindi malinaw ang senyas, subukan ulit'
                                      : null,
                                ),
                                const SizedBox(height: 8),

                                // ── Thumbs up / down feedback ──
                                if (_currentSign.isNotEmpty)
                                  _FeedbackRow(
                                    feedbackValue: _feedbackValue,
                                    feedbackSubmitted: _feedbackSubmitted,
                                    darkMode: darkMode,
                                    onThumbsUp: () => _handleFeedback(true),
                                    onThumbsDown: () => _handleFeedback(false),
                                  ),
                                const SizedBox(height: 12),

                                // Sentence output
                                _SentenceOutput(
                                  sentence: _sentence,
                                  isDetecting: _isDetecting,
                                  canClear: _canClear,
                                  onClear: _handleClear,
                                  darkMode: darkMode,
                                ),
                                const SizedBox(height: 12),

                                // Start / Stop buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ActionButton(
                                        label: 'Simulan',
                                        icon: Icons.play_arrow,
                                        enabled:
                                            !_isDetecting &&
                                            _cameraReady &&
                                            !_isAnalyzingVideo,
                                        color: ESenyasColors.accentGreen,
                                        disabledDark: darkMode,
                                        onTap: _handleStart,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _ActionButton(
                                        label: 'Itigil',
                                        icon: Icons.stop,
                                        enabled: _isDetecting,
                                        color: ESenyasColors.destructiveRed,
                                        disabledDark: darkMode,
                                        onTap: _handleStop,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Save button
                                SizedBox(
                                  width: double.infinity,
                                  height: ESenyasDimens.buttonHeight,
                                  child: ElevatedButton.icon(
                                    onPressed: _canSave ? _handleSave : null,
                                    icon: const Icon(Icons.save, size: 18),
                                    label: const Text('I-save sa Kasaysayan'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: darkMode
                                          ? ESenyasColors.primaryBlueDark
                                          : ESenyasColors.primaryBlue,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: darkMode
                                          ? ESenyasColors.gray700
                                          : const Color(0xFFE5E7EB),
                                      disabledForegroundColor: darkMode
                                          ? ESenyasColors.gray500
                                          : ESenyasColors.gray400,
                                      elevation: _canSave ? 1 : 0,
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
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Toast
                  if (_savedToast)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: ESenyasColors.accentGreen,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Na-save sa Kasaysayan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const ESenyasBottomNavBar(currentIndex: 1),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Camera section widget
  // ──────────────────────────────────────────────────────────

  Widget _buildCameraSection(bool darkMode) {
    // Permission denied state
    if (!_permissionGranted) {
      return _CameraFallback(
        icon: Icons.no_photography,
        message: 'Kailangan ng pahintulot sa Camera.\n'
            'Buksan ang Settings para payagan.',
        darkMode: darkMode,
        action: TextButton(
          onPressed: openAppSettings,
          child: const Text('Buksan ang Settings'),
        ),
      );
    }

    // Loading / initialising state
    if (!_cameraReady || _cameraController == null) {
      return _CameraFallback(
        icon: Icons.camera_alt_outlined,
        message: 'Sinisimulan ang camera...',
        darkMode: darkMode,
        showSpinner: true,
      );
    }

    // Live CameraPreview with adjustable height
    return Column(
      children: [
        Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOut,
              height: _cameraHeight,
              width: double.infinity,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _cameraController!.value.previewSize!.height,
                      height: _cameraController!.value.previewSize!.width,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: ValueListenableBuilder<List<Hand>>(
                valueListenable: _latestHands,
                builder: (context, hands, _) {
                  return HandLandmarkOverlay(
                    hands: hands,
                    previewSize: _cameraController!.value.previewSize!,
                    lensDirection: _lensDirection,
                    sensorOrientation: _sensorOrientation,
                  );
                },
              ),
            ),
            Positioned(
              top: 10,
              left: 12,
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
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: switch (_phase) {
                    SignPhase.signing => SignGestureAnimation(
                      key: const ValueKey(SignPhase.signing),
                      darkMode: darkMode,
                      duration: _signDuration,
                    ),
                    SignPhase.analyzing => AnalyzingAnimation(
                      key: const ValueKey(SignPhase.analyzing),
                      darkMode: darkMode,
                    ),
                    SignPhase.idle => const SizedBox.shrink(),
                  },
                ),
              ),
            ),
            // Camera flip button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _isDetecting ? null : _handleFlipCamera,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.flip_camera_android,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            // Frame size indicator
            Positioned(
              bottom: 28,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_cameraHeight.round()}px',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        // ── Drag handle to resize camera frame ──
        GestureDetector(
          onVerticalDragUpdate: (details) {
            setState(() {
              _cameraHeight = (_cameraHeight + details.delta.dy)
                  .clamp(_cameraHeightMin, _cameraHeightMax);
            });
          },
          child: Container(
            width: double.infinity,
            height: 20,
            color: darkMode ? ESenyasColors.cardDark : const Color(0xFFF0F0F0),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: darkMode ? ESenyasColors.gray600 : ESenyasColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// _CameraFallback — shown while loading or if permission denied
// ──────────────────────────────────────────────────────────────

class _CameraFallback extends StatelessWidget {
  final IconData icon;
  final String message;
  final bool darkMode;
  final bool showSpinner;
  final Widget? action;

  const _CameraFallback({
    required this.icon,
    required this.message,
    required this.darkMode,
    this.showSpinner = false,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ESenyasDimens.cameraPreviewHeight,
      width: double.infinity,
      color: darkMode ? ESenyasColors.cardDark : ESenyasColors.gray800,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showSpinner)
            const CircularProgressIndicator(color: Colors.white54)
          else
            Icon(icon, color: Colors.white54, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Thumbs up / down feedback widget
// ──────────────────────────────────────────────────────────────

class _FeedbackRow extends StatelessWidget {
  final bool? feedbackValue;
  final bool feedbackSubmitted;
  final bool darkMode;
  final VoidCallback onThumbsUp;
  final VoidCallback onThumbsDown;

  const _FeedbackRow({
    required this.feedbackValue,
    required this.feedbackSubmitted,
    required this.darkMode,
    required this.onThumbsUp,
    required this.onThumbsDown,
  });

  @override
  Widget build(BuildContext context) {
    // After submitting feedback, show a brief thank-you message
    if (feedbackSubmitted && feedbackValue != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Icon(
              feedbackValue! ? Icons.thumb_up : Icons.thumb_down,
              size: 14,
              color: feedbackValue!
                  ? ESenyasColors.accentGreen
                  : ESenyasColors.destructiveRed,
            ),
            const SizedBox(width: 6),
            Text(
              feedbackValue!
                  ? 'Salamat sa iyong feedback!'
                  : 'Salamat! Pagbubutihin pa namin.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: darkMode ? ESenyasColors.gray400 : ESenyasColors.gray500,
              ),
            ),
          ],
        ),
      );
    }

    // Feedback buttons
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            'Tama ba ang resulta?',
            style: TextStyle(
              fontSize: 12,
              color: darkMode ? ESenyasColors.gray400 : ESenyasColors.gray500,
            ),
          ),
          const SizedBox(width: 12),
          _FeedbackButton(
            icon: Icons.thumb_up_outlined,
            activeIcon: Icons.thumb_up,
            label: 'Oo',
            isSelected: feedbackValue == true,
            color: ESenyasColors.accentGreen,
            darkMode: darkMode,
            onTap: onThumbsUp,
          ),
          const SizedBox(width: 8),
          _FeedbackButton(
            icon: Icons.thumb_down_outlined,
            activeIcon: Icons.thumb_down,
            label: 'Hindi',
            isSelected: feedbackValue == false,
            color: ESenyasColors.destructiveRed,
            darkMode: darkMode,
            onTap: onThumbsDown,
          ),
        ],
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final Color color;
  final bool darkMode;
  final VoidCallback onTap;

  const _FeedbackButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.darkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : (darkMode ? ESenyasColors.gray700 : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 14,
              color: isSelected
                  ? color
                  : (darkMode ? ESenyasColors.gray400 : ESenyasColors.gray500),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? color
                    : (darkMode ? ESenyasColors.gray400 : ESenyasColors.gray500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Private UI widgets — unchanged from original screen
// ──────────────────────────────────────────────────────────────

class _DetectionStatusPill extends StatelessWidget {
  final String status;
  final String currentSign;
  final int confidence;
  final bool darkMode;
  final String? statusText;

  const _DetectionStatusPill({
    required this.status,
    required this.currentSign,
    required this.confidence,
    required this.darkMode,
    this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final String text;

    if (statusText != null && statusText!.isNotEmpty) {
      dotColor = const Color(0xFF38BDF8); // sky-400
      text = statusText!;
    } else {
      switch (status) {
        case 'detected':
          dotColor = ESenyasColors.accentGreen;
          text = 'Natukoy: "$currentSign" — $confidence%';
          break;
        case 'signing':
          dotColor = const Color(0xFFFACC15); // yellow-400
          text = 'Gawin ang senyas ngayon...';
          break;
        case 'analyzing':
          dotColor = ESenyasColors.primaryBlue;
          text = 'Sinusuri...';
          break;
        default:
          dotColor = ESenyasColors.gray300;
          text = 'Walang Natukoy na Kamay';
      }
    }

    return Row(
      children: [
        _StatusDot(
          color: dotColor,
          pulsing: status == 'signing' || status == 'analyzing',
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: darkMode ? const Color(0xFFD1D5DB) : ESenyasColors.gray600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatefulWidget {
  final Color color;
  final bool pulsing;

  const _StatusDot({required this.color, this.pulsing = false});

  @override
  State<_StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<_StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.pulsing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulsing && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: widget.pulsing
          ? _controller
          : const AlwaysStoppedAnimation(1.0),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _SentenceOutput extends StatelessWidget {
  final String sentence;
  final bool isDetecting;
  final bool canClear;
  final VoidCallback onClear;
  final bool darkMode;

  const _SentenceOutput({
    required this.sentence,
    required this.isDetecting,
    required this.canClear,
    required this.onClear,
    required this.darkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Buong Pangungusap',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: darkMode ? const Color(0xFFD1D5DB) : ESenyasColors.gray700,
              ),
            ),
            if (canClear)
              GestureDetector(
                onTap: onClear,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 11,
                      color: darkMode
                          ? ESenyasColors.gray500
                          : ESenyasColors.gray400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'I-clear',
                      style: TextStyle(
                        fontSize: 12,
                        color: darkMode
                            ? ESenyasColors.gray500
                            : ESenyasColors.gray400,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 90),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: darkMode ? ESenyasColors.cardDark : Colors.white,
            borderRadius:
                BorderRadius.circular(ESenyasDimens.borderRadiusMd),
            border: Border.all(color: ESenyasColors.accentGreen, width: 2),
          ),
          child: sentence.isNotEmpty
              ? RichText(
                  text: TextSpan(
                    text: sentence,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: ESenyasColors.accentGreen,
                      height: 1.3,
                    ),
                    children: isDetecting
                        ? [
                            WidgetSpan(
                              child: _BlinkingCursor(),
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                            ),
                          ]
                        : null,
                  ),
                )
              : Center(
                  child: Text(
                    isDetecting
                        ? 'Naghihintay ng unang senyas...'
                        : 'Pindutin ang Simulan para magsimula',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: darkMode
                          ? ESenyasColors.gray600
                          : ESenyasColors.gray300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      ],
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 22,
        margin: const EdgeInsets.only(left: 2),
        decoration: BoxDecoration(
          color: ESenyasColors.accentGreen,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final Color color;
  final bool disabledDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.color,
    required this.disabledDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ESenyasDimens.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: disabledDark
              ? ESenyasColors.gray700
              : const Color(0xFFE5E7EB),
          disabledForegroundColor: disabledDark
              ? ESenyasColors.gray500
              : ESenyasColors.gray400,
          elevation: enabled ? 1 : 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(ESenyasDimens.borderRadiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
