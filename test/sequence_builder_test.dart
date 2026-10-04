import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:esenyas/models/frame_landmarks.dart';
import 'package:esenyas/services/tflite_ai_service.dart';

void main() {
  group('TFLiteAIService Preprocessing and SequenceBuilder', () {
    test('buildSequence matches golden.sequence within 1e-4', () {
      final file = File('assets/test/golden.json');
      expect(file.existsSync(), isTrue, reason: 'assets/test/golden.json must exist');

      final jsonStr = file.readAsStringSync();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final rawFrames = data['frames'] as List<dynamic>;
      final frames = rawFrames.map<FrameLandmarks>((frameJson) {
        final handsList = frameJson as List<dynamic>;
        if (handsList.isEmpty) {
          return const FrameLandmarks.noHand();
        }
        final hands = handsList.map<List<List<double>>>((handJson) {
          final lms = handJson as List<dynamic>;
          return lms.map<List<double>>((ptJson) {
            final pt = ptJson as List<dynamic>;
            return [
              (pt[0] as num).toDouble(),
              (pt[1] as num).toDouble(),
              (pt[2] as num).toDouble(),
            ];
          }).toList();
        }).toList();
        return FrameLandmarks(handDetected: true, hands: hands);
      }).toList();

      final builtSeq = TFLiteAIService.buildSequence(frames);
      expect(builtSeq, isNotNull);
      expect(builtSeq!.length, equals(45));

      final goldenSeq = (data['sequence'] as List<dynamic>)
          .map((row) =>
              (row as List<dynamic>).map((v) => (v as num).toDouble()).toList())
          .toList();

      double maxDiff = 0.0;
      for (int i = 0; i < 45; i++) {
        expect(builtSeq[i].length, equals(126));
        for (int j = 0; j < 126; j++) {
          final diff = (builtSeq[i][j] - goldenSeq[i][j]).abs();
          if (diff > maxDiff) maxDiff = diff;
          expect(builtSeq[i][j], closeTo(goldenSeq[i][j], 1e-4),
              reason: 'Mismatch at frame $i, feature $j: built=${builtSeq[i][j]}, golden=${goldenSeq[i][j]}');
        }
      }
      expect(maxDiff, lessThan(1e-4));
    });

    test('no hands in buffer returns null', () {
      final buffer = List<FrameLandmarks>.generate(
        30,
        (_) => const FrameLandmarks.noHand(),
      );
      expect(TFLiteAIService.buildSequence(buffer), isNull);
    });

    test('fewer than 8 active frames returns null', () {
      // 7 active frames, 10 empty frames
      List<List<double>> makeSingleHand() =>
          List.generate(21, (idx) => [0.3, 0.4, 0.0]);

      final buffer = [
        for (int i = 0; i < 7; i++)
          FrameLandmarks(
            handDetected: true,
            hands: [makeSingleHand()],
          ),
        for (int i = 0; i < 10; i++) const FrameLandmarks.noHand(),
      ];

      expect(TFLiteAIService.buildSequence(buffer), isNull);
    });

    test('8 active frames produces a sequence', () {
      List<List<double>> makeSingleHand() =>
          List.generate(21, (idx) => [0.3 + idx * 0.01, 0.4, 0.0]);

      final buffer = [
        for (int i = 0; i < 8; i++)
          FrameLandmarks(
            handDetected: true,
            hands: [makeSingleHand()],
          ),
      ];

      final seq = TFLiteAIService.buildSequence(buffer);
      expect(seq, isNotNull);
      expect(seq!.length, equals(45));
    });

    test('two hands are ordered by wrist x ascending, not by list order', () {
      // Hand Left (wrist x = 0.2)
      final handLeft = List.generate(21, (i) => [0.2 + (i * 0.005), 0.5, 0.1]);
      // Hand Right (wrist x = 0.8)
      final handRight = List.generate(21, (i) => [0.8 + (i * 0.005), 0.6, 0.2]);

      // Frame with [handRight, handLeft]
      final frame1 = FrameLandmarks(
        handDetected: true,
        hands: [handRight, handLeft],
      );

      // Frame with [handLeft, handRight]
      final frame2 = FrameLandmarks(
        handDetected: true,
        hands: [handLeft, handRight],
      );

      final feats1 = TFLiteAIService.frameFeatures(frame1);
      final feats2 = TFLiteAIService.frameFeatures(frame2);

      // Both should result in handLeft in slot 0 (0..62) and handRight in slot 1 (63..125)
      expect(feats1, equals(feats2));

      // Verify slot 0 wrist landmark is subtracted:
      // Landmark 1 in handLeft: [0.205, 0.5, 0.1] - [0.2, 0.5, 0.1] = [0.005, 0.0, 0.0]
      expect(feats1[0], closeTo(0.0, 1e-6));
      expect(feats1[1], closeTo(0.0, 1e-6));
      expect(feats1[2], closeTo(0.0, 1e-6));
      expect(feats1[3], closeTo(0.005, 1e-6));

      // Slot 1 (offset 63) is handRight:
      // Wrist is at 63, 64, 65 = 0.0
      expect(feats1[63], closeTo(0.0, 1e-6));
      expect(feats1[64], closeTo(0.0, 1e-6));
      expect(feats1[65], closeTo(0.0, 1e-6));
      expect(feats1[66], closeTo(0.005, 1e-6));
    });
  });
}
