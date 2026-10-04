import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Signing countdown prompt. The skeleton remains visible through the pill.
class SignGestureAnimation extends StatefulWidget {
  final bool darkMode;
  final Duration duration;
  final String label;
  final String? hint;

  const SignGestureAnimation({
    super.key,
    required this.darkMode,
    required this.duration,
    this.label = 'Mag-sign na!',
    this.hint,
  });

  @override
  State<SignGestureAnimation> createState() => _SignGestureAnimationState();
}

class _SignGestureAnimationState extends State<SignGestureAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _progressController;
  late final Animation<double> _wave;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _wave = Tween<double>(begin: -math.pi / 15, end: math.pi / 15).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blue = widget.darkMode
        ? ESenyasColors.lightBlueText
        : ESenyasColors.primaryBlue;
    return _CapturePill(
      darkMode: widget.darkMode,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_waveController, _progressController]),
            builder: (context, _) {
              final seconds =
                  (widget.duration.inMilliseconds /
                          1000 *
                          (1 - _progressController.value))
                      .ceil();
              return SizedBox(
                width: 54,
                height: 54,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: _progressController.value,
                        strokeWidth: 3,
                        color: ESenyasColors.accentGreen,
                        backgroundColor: blue.withValues(alpha: 0.2),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: _wave.value,
                          child: Icon(
                            Icons.waving_hand_rounded,
                            color: blue,
                            size: 24,
                          ),
                        ),
                        Text(
                          '$seconds',
                          style: TextStyle(
                            color: blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(color: blue, fontWeight: FontWeight.w600),
                ),
                if (widget.hint != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.hint!,
                    style: TextStyle(color: blue, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Three staggered bouncing dots while the captured landmarks are analyzed.
class AnalyzingAnimation extends StatefulWidget {
  final bool darkMode;

  const AnalyzingAnimation({super.key, required this.darkMode});

  @override
  State<AnalyzingAnimation> createState() => _AnalyzingAnimationState();
}

class _AnalyzingAnimationState extends State<AnalyzingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blue = widget.darkMode
        ? ESenyasColors.lightBlueText
        : ESenyasColors.primaryBlue;
    return _CapturePill(
      darkMode: widget.darkMode,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 54,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Transform.translate(
                      offset: Offset(
                        0,
                        -8 *
                            math.sin(
                              math.pi *
                                  Interval(
                                    i * 0.15,
                                    0.5 + i * 0.15,
                                    curve: Curves.easeInOut,
                                  ).transform(_controller.value),
                            ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: ESenyasColors.accentGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Sinusuri...',
            style: TextStyle(color: blue, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CapturePill extends StatelessWidget {
  final bool darkMode;
  final Widget child;

  const _CapturePill({required this.darkMode, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: (darkMode ? ESenyasColors.cardDark : ESenyasColors.cardLight)
          .withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(ESenyasDimens.borderRadiusXl),
      border: Border.all(
        color: ESenyasColors.primaryBlue.withValues(alpha: 0.3),
      ),
    ),
    child: child,
  );
}
