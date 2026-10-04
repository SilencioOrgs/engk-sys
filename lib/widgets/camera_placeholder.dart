import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Camera placeholder widget used on Translation and Testing screens.
///
/// Shows a dark preview area with grid lines, hand‐position guide,
/// optional REC indicator, camera mode label, and flip button.
class CameraPlaceholder extends StatelessWidget {
  final bool isRecording;
  final String cameraMode; // 'harap' or 'likod'
  final VoidCallback? onFlipCamera;
  final double height;

  const CameraPlaceholder({
    super.key,
    this.isRecording = false,
    this.cameraMode = 'harap',
    this.onFlipCamera,
    this.height = ESenyasDimens.cameraPreviewHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: const Color(0xFF111827), // gray-900
      child: Stack(
        children: [
          // Center camera icon
          const Center(
            child: Icon(Icons.camera_alt, size: 40, color: Color(0xFF4B5563)),
          ),

          // Grid lines
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: ESenyasColors.accentGreen.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Horizontal thirds
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          const Spacer(),
                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          const Spacer(),
                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    // Vertical thirds
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Row(
                        children: [
                          const Spacer(),
                          VerticalDivider(
                            width: 1,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          const Spacer(),
                          VerticalDivider(
                            width: 1,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Hand guide box
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Ilagay ang kamay dito',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),

          // REC indicator
          if (isRecording)
            Positioned(
              top: 10,
              left: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PulsingDot(color: Colors.red, size: 8),
                  const SizedBox(width: 6),
                  const Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Camera mode label
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cameraMode == 'harap' ? 'Harap' : 'Likod',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),

          // Flip camera button
          if (onFlipCamera != null)
            Positioned(
              bottom: 10,
              right: 10,
              child: Material(
                color: Colors.white.withValues(alpha: 0.9),
                shape: const CircleBorder(),
                elevation: 3,
                child: InkWell(
                  onTap: onFlipCamera,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.cameraswitch,
                      size: 18,
                      color: ESenyasColors.primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small pulsing dot used as the REC indicator.
class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const _PulsingDot({required this.color, required this.size});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
