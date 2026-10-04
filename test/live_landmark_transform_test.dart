import 'dart:ui' show Size;

import 'package:esenyas/utils/live_landmark_transform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tolerance = 1e-6;

  group('LiveLandmarkTransform.toTrainingSpaceRaw', () {
    test('270-degree sensor rotates an upward finger and converts aspect', () {
      final hand = LiveLandmarkTransform.toTrainingSpaceRaw(
        [
          [
            [0.5, 0.5, 0.0],
            [0.7, 0.5, 0.0],
          ],
        ],
        sensorOrientation: 270,
        rawFrameSize: const Size(720, 480),
      ).single;

      expect(hand[1][0] - hand[0][0], closeTo(0.0, tolerance));
      expect(hand[1][1] - hand[0][1], closeTo(-0.30, tolerance));
    });

    test('two wrist x values preserve unmirrored order', () {
      final hands = LiveLandmarkTransform.toTrainingSpaceRaw(
        [
          [
            [0.5, 0.3, 0.0],
          ],
          [
            [0.5, 0.7, 0.0],
          ],
        ],
        sensorOrientation: 270,
        rawFrameSize: const Size(720, 480),
      );

      expect(hands[0][0][0], closeTo(0.2, tolerance));
      expect(hands[1][0][0], closeTo(0.4666666667, tolerance));
      expect(hands[0][0][0], lessThan(hands[1][0][0]));
    });

    test('upright 1280x720 input is unchanged', () {
      final input = [
        [
          [0.5, 0.5, 0.0],
          [0.3, 0.8, -0.2],
        ],
      ];
      final output = LiveLandmarkTransform.toTrainingSpaceRaw(
        input,
        sensorOrientation: 0,
        rawFrameSize: const Size(1280, 720),
      );

      for (var p = 0; p < input.single.length; p++) {
        for (var axis = 0; axis < 3; axis++) {
          expect(output[0][p][axis], closeTo(input[0][p][axis], tolerance));
        }
      }
    });

    test('90-degree sensor rotates an upward finger and converts aspect', () {
      final hand = LiveLandmarkTransform.toTrainingSpaceRaw(
        [
          [
            [0.5, 0.5, 0.0],
            [0.3, 0.5, 0.0],
          ],
        ],
        sensorOrientation: 90,
        rawFrameSize: const Size(720, 480),
      ).single;

      expect(hand[1][0] - hand[0][0], closeTo(0.0, tolerance));
      expect(hand[1][1] - hand[0][1], closeTo(-0.30, tolerance));
    });

    test('z values remain unchanged for every sensor rotation', () {
      for (final orientation in [0, 90, 180, 270, -90, 450]) {
        final hand = LiveLandmarkTransform.toTrainingSpaceRaw(
          [
            [
              [0.5, 0.5, 0.12],
              [0.7, 0.5, -0.34],
            ],
          ],
          sensorOrientation: orientation,
          rawFrameSize: const Size(720, 480),
        ).single;

        expect(hand[0][2], closeTo(0.12, tolerance));
        expect(hand[1][2], closeTo(-0.34, tolerance));
      }
    });
  });
}
