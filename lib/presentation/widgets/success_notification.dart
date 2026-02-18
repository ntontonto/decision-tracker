import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/app_providers.dart';
import '../theme/app_design.dart';

class SuccessNotification extends ConsumerStatefulWidget {
  const SuccessNotification({super.key});

  @override
  ConsumerState<SuccessNotification> createState() => _SuccessNotificationState();
}

class _SuccessNotificationState extends ConsumerState<SuccessNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetDrag() {
    setState(() {
      _dragOffset = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(successNotificationProvider);
    
    ref.listen(successNotificationProvider, (prev, next) {
      if (next.isVisible) {
        _resetDrag();
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });

    return SlideTransition(
      position: _slideAnimation,
      child: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (details) {
            setState(() {
              // Only allow upward drag, and limit it
              _dragOffset = (_dragOffset + details.delta.dy).clamp(-100.0, 20.0);
            });
          },
          onVerticalDragEnd: (details) {
            if (_dragOffset < -50 || (details.primaryVelocity ?? 0) < -300) {
              ref.read(successNotificationProvider.notifier).hide();
            } else {
              // Snap back
              setState(() {
                _dragOffset = 0;
              });
            }
          },
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: _dragOffset, end: _dragOffset),
            duration: const Duration(milliseconds: 50),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Increased vertical padding from 4 to 8
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: (1.0 + _dragOffset / 100.0).clamp(0.2, 1.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // Increased vertical padding from 10 to 16
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E), // Opaque dark grey
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (state.icon != null) ...[
                        Icon(
                          state.icon,
                          color: Colors.white,
                          size: 24, // Increased from 20
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          state.message,
                          style: const TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.w600, // Increased from w500
                            fontSize: 15, // Added font size
                          ),
                        ),
                      ),
                      if (state.onFix != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: GestureDetector(
                            onTap: () {
                              state.onFix?.call(context, ref);
                              ref.read(successNotificationProvider.notifier).hide();
                            },
                            child: const Text(
                              '修正する',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      const _ProgressIndicator(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressIndicator extends ConsumerStatefulWidget {
  const _ProgressIndicator();

  @override
  ConsumerState<_ProgressIndicator> createState() => _ProgressIndicatorState();
}

class _ProgressIndicatorState extends ConsumerState<_ProgressIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    
    ref.listenManual(successNotificationProvider, (prev, next) {
      if (next.isVisible) {
        _controller.reset();
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(20, 20),
          painter: _CirclePainter(progress: 1.0 - _controller.value),
        );
      },
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  _CirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(size.center(Offset.zero), size.width / 2, paint);
    
    final activePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
