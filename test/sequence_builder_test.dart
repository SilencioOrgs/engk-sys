import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:esenyas/models/frame_landmarks.dart';
import 'package:esenyas/services/tflite_ai_service.dart';

void main() {
  group('Timestamp-based SequenceBuilder', () {
    late List<FrameLandmarks> frames;
    late List<int> timestamps;

    setUpAll(() {
      frames = _loadGoldenFrames();
      timestamps = [
        for (var i = 0; i < frames.length; i++) (i * 1000 / 30).round(),
      ];
    });

    test('uniform 30 fps matches the untimed sequence within 1e-4', () {
      // Include both rounded-up and rounded-down final timestamps.
      for (final length in [
        frames.length,
        frames.length - 1,
        frames.length - 2,
      ]) {
        final buffer = frames.sublist(0, length);
        final expected = TFLiteAIService.buildSequence(buffer)!;
        final actual = TFLiteAIService.buildSequenceTimed(
          buffer,
          timestamps.sublist(0, length),
        );
        expect(actual, isNotNull);
        var maxDiff = 0.0;
        for (var i = 0; i < 45; i++) {
          expect(actual![i].length, 126);
          for (var k = 0; k < 126; k++) {
            final diff = (actual[i][k] - expected[i][k]).abs();
            if (diff > maxDiff) maxDiff = diff;
          }
        }
        expect(maxDiff, lessThan(1e-4));
      }
    });

    test('10 fps capture stays finite and close to the full-rate sequence', () {
      final sparseFrames = [
        for (var i = 0; i < frames.length; i += 3) frames[i],
      ];
      final sparseTimes = [
        for (var i = 0; i < frames.length; i += 3) timestamps[i],
      ];
      final expected = TFLiteAIService.buildSequence(frames)!;
      final actual = TFLiteAIService.buildSequenceTimed(
        sparseFrames,
        sparseTimes,
      );
      expect(actual, isNotNull);
      expect(actual!.length, 45);
      var totalDiff = 0.0;
      for (var i = 0; i < 45; i++) {
        expect(actual[i].length, 126);
        for (var k = 0; k < 126; k++) {
          expect(actual[i][k].isFinite, isTrue);
          totalDiff += (actual[i][k] - expected[i][k]).abs();
        }
      }
      expect(totalDiff / (45 * 126), lessThan(0.01));
    });

    test('fewer than 8 original active frames returns null', () {
      final sparseFrames = frames
          .where((f) => f.handDetected && f.hands.isNotEmpty)
          .take(7)
          .toList();
      expect(sparseFrames.length, 7);
      final sparseTimes = [
        for (var i = 0; i < sparseFrames.length; i++) i * 100,
      ];
      expect(
        TFLiteAIService.buildSequenceTimed(sparseFrames, sparseTimes),
        isNull,
      );
    });

    test('mismatched timestamp count falls back, including mirrorX', () {
      for (final mirrorX in [false, true]) {
        expect(
          TFLiteAIService.buildSequenceTimed(
            frames,
            timestamps.sublist(1),
            mirrorX: mirrorX,
          ),
          equals(TFLiteAIService.buildSequence(frames, mirrorX: mirrorX)),
        );
      }
    });

    test('uneven callbacks interpolate motion by elapsed time', () {
      final times = [0, 25, 70, 180, 200, 235, 360, 400];
      final buffer = [for (final t in times) _movingHandFrame(t)];
      final sequence = TFLiteAIService.buildSequenceTimed(buffer, times)!;
      for (final sample in {0: 0, 11: 100, 22: 200, 33: 300, 44: 400}.entries) {
        expect(
          sequence[sample.key][3],
          closeTo(0.01 + sample.value * 0.0005, 1e-6),
        );
      }
    });

    test(
      'missing or changing hand sets use nearest frames without blending',
      () {
        final times = [for (var i = 0; i <= 10; i++) i * 100];
        final buffer = [
          for (final t in times)
            t == 400
                ? const FrameLandmarks.noHand()
                : _movingHandFrame(t, twoHands: t == 800),
        ];
        final sequence = TFLiteAIService.buildSequenceTimed(buffer, times)!;
        // 366.7 and 433.3 ms both select the missing-hand frame at 400 ms.
        expect(sequence[17], everyElement(0.0));
        expect(sequence[20], everyElement(0.0));
        // 466.7 ms selects the actual 500 ms frame, without blending in zeros.
        expect(sequence[21][3], closeTo(0.26, 1e-6));
        // 766.7 ms selects the full two-hand frame at 800 ms.
        expect(sequence[34][3], closeTo(0.41, 1e-6));
        expect(sequence[34][66], closeTo(0.2, 1e-6));
        // 866.7 ms selects the one-hand frame at 900 ms.
        expect(sequence[39][3], closeTo(0.46, 1e-6));
        expect(sequence[39].sublist(63), everyElement(0.0));
      },
    );
  });

  group('TFLiteAIService Preprocessing and SequenceBuilder', () {
    test('buildSequence matches golden.sequence within 1e-4', () {
      final file = File('assets/test/golden.json');
      expect(
        file.existsSync(),
        isTrue,
        reason: 'assets/test/golden.json must exist',
      );

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
          .map(
            (row) => (row as List<dynamic>)
                .map((v) => (v as num).toDouble())
                .toList(),
          )
          .toList();

      double maxDiff = 0.0;
      for (int i = 0; i < 45; i++) {
        expect(builtSeq[i].length, equals(126));
        for (int j = 0; j < 126; j++) {
          final diff = (builtSeq[i][j] - goldenSeq[i][j]).abs();
          if (diff > maxDiff) maxDiff = diff;
          expect(
            builtSeq[i][j],
            closeTo(goldenSeq[i][j], 1e-4),
            reason:
                'Mismatch at frame $i, feature $j: built=${builtSeq[i][j]}, golden=${goldenSeq[i][j]}',
          );
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
          FrameLandmarks(handDetected: true, hands: [makeSingleHand()]),
        for (int i = 0; i < 10; i++) const FrameLandmarks.noHand(),
      ];

      expect(TFLiteAIService.buildSequence(buffer), isNull);
    });

    test('8 active frames produces a sequence', () {
      List<List<double>> makeSingleHand() =>
          List.generate(21, (idx) => [0.3 + idx * 0.01, 0.4, 0.0]);

      final buffer = [
        for (int i = 0; i < 8; i++)
          FrameLandmarks(handDetected: true, hands: [makeSingleHand()]),
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

List<FrameLandmarks> _loadGoldenFrames() {
  final data =
      jsonDecode(File('assets/test/golden.json').readAsStringSync())
          as Map<String, dynamic>;
  return (data['frames'] as List<dynamic>).map((frame) {
    final rawHands = frame as List<dynamic>;
    if (rawHands.isEmpty) return const FrameLandmarks.noHand();
    return FrameLandmarks(
      handDetected: true,
      hands: [
        for (final hand in rawHands)
          [
            for (final point in hand as List<dynamic>)
              [for (final v in point as List<dynamic>) (v as num).toDouble()],
          ],
      ],
    );
  }).toList();
}

FrameLandmarks _movingHandFrame(int timestampMs, {bool twoHands = false}) =>
    FrameLandmarks(
      handDetected: true,
      hands: [
        [
          [0.1, 0.2, 0.0],
          for (var i = 1; i < 21; i++) [0.11 + timestampMs * 0.0005, 0.2, 0.0],
        ],
        if (twoHands)
          [
            [0.7, 0.2, 0.0],
            for (var i = 1; i < 21; i++) [0.9, 0.2, 0.0],
          ],
      ],
    );
