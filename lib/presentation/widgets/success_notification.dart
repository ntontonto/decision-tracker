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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(successNotificationProvider);
    
    ref.listen(successNotificationProvider, (prev, next) {
      if (next.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });

    return SlideTransition(
      position: _slideAnimation,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Reduced vertical padding
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Reduced vertical padding
            decoration: BoxDecoration(
              color: AppDesign.glassBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppDesign.glassBorderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.message,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
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
