import 'package:flutter/services.dart';

import '../models/frame_landmarks.dart';

class VideoLandmarkResult {
  final List<FrameLandmarks> frames;
  final int durationMs;
  final double sourceFps;
  final int sampledFrames;
  final int activeFrames;
  final int width;
  final int height;

  const VideoLandmarkResult({
    required this.frames,
    required this.durationMs,
    required this.sourceFps,
    required this.sampledFrames,
    required this.activeFrames,
    required this.width,
    required this.height,
  });

  factory VideoLandmarkResult.fromMap(Map<dynamic, dynamic> map) {
    final rawFrames = map['frames'] as List<dynamic>? ?? const [];

    final frames = rawFrames.map<FrameLandmarks>((rawFrame) {
      final rawHands = rawFrame as List<dynamic>;
      if (rawHands.isEmpty) return const FrameLandmarks.noHand();

      final hands = rawHands.map<List<List<double>>>((rawHand) {
        final rawLandmarks = rawHand as List<dynamic>;
        return rawLandmarks.map<List<double>>((rawPoint) {
          final point = rawPoint as List<dynamic>;
          return [
            (point[0] as num).toDouble(),
            (point[1] as num).toDouble(),
            (point[2] as num).toDouble(),
          ];
        }).toList();
      }).toList();

      return FrameLandmarks(handDetected: true, hands: hands);
    }).toList();

    return VideoLandmarkResult(
      frames: frames,
      durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
      sourceFps: (map['sourceFps'] as num?)?.toDouble() ?? 0,
      sampledFrames: (map['sampledFrames'] as num?)?.toInt() ?? frames.length,
      activeFrames: (map['activeFrames'] as num?)?.toInt() ??
          frames.where((frame) => frame.handDetected).length,
      width: (map['width'] as num?)?.toInt() ?? 0,
      height: (map['height'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Offline Android video analysis using MediaPipe Hand Landmarker VIDEO mode.
///
/// The returned landmarks are fed through the same buildSequence() and TFLite
/// classifier used by live camera captures.
class VideoLandmarkService {
  static const MethodChannel _channel =
      MethodChannel('esenyas/video_landmarks');

  Future<VideoLandmarkResult> analyzeVideo(
    String path, {
    bool rotateClockwise90 = false,
  }) async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'analyzeVideo',
      {
        'path': path,
        'rotateClockwise90': rotateClockwise90,
      },
    );

    if (result == null) {
      throw StateError('Native video analysis returned no result.');
    }

    return VideoLandmarkResult.fromMap(result);
  }
}
