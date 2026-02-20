import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/settings_provider.dart';

class OnboardingOverlay extends ConsumerStatefulWidget {
  final GlobalKey? addButtonKey;
  final GlobalKey? constellationButtonKey;
  final bool isConstellationView;

  const OnboardingOverlay({
    super.key,
    this.addButtonKey,
    this.constellationButtonKey,
    this.isConstellationView = false,
  });

  @override
  ConsumerState<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends ConsumerState<OnboardingOverlay> {
  Rect? _targetRect;
  Rect? _addRect;
  Rect? _constellationRect;

  @override
  void initState() {
    super.initState();
    _updateRects();
  }

  void _updateRects() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final step = ref.read(settingsProvider).onboardingStep;
      
      Rect? newAddRect;
      if (widget.addButtonKey != null) {
        newAddRect = _getWidgetRect(widget.addButtonKey!);
      }
      
      Rect? newConstellationRect;
      if (widget.constellationButtonKey != null) {
        newConstellationRect = _getWidgetRect(widget.constellationButtonKey!);
      }
      
      Rect? newTargetRect;
      if (step == 0) {
        newTargetRect = newAddRect;
      } else if (step == 2) {
        newTargetRect = newConstellationRect;
      }

      if (newTargetRect != _targetRect || newAddRect != _addRect || newConstellationRect != _constellationRect) {
        setState(() {
          _targetRect = newTargetRect;
          _addRect = newAddRect;
          _constellationRect = newConstellationRect;
        });
      }
      
      // Continue updating if necessary
      if ((step == 0 && newAddRect == null && widget.addButtonKey != null) || 
          (step == 2 && newConstellationRect == null && widget.constellationButtonKey != null) ||
          ((step == 1 || step == 3) && (newAddRect == null && widget.addButtonKey != null || newConstellationRect == null && widget.constellationButtonKey != null))) {
        Future.delayed(const Duration(milliseconds: 200), _updateRects);
      }
    });
  }

  Rect? _getWidgetRect(GlobalKey key) {
    try {
      final context = key.currentContext;
      if (context == null) return null;
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return null;
      final offset = renderBox.localToGlobal(Offset.zero);
      return offset & renderBox.size;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    if (settings.hasSeenOnboarding) return const SizedBox.shrink();

    // Step 3 is only for Constellation View. On Home screen, hide it to avoid flashes during transition.
    if (settings.onboardingStep == 3 && !widget.isConstellationView) {
      return const SizedBox.shrink();
    }

    ref.listen(settingsProvider.select((s) => s.onboardingStep), (previous, current) {
      _updateRects();
    });

    return Stack(
      children: [
        // 1. Visual Background (Non-interactive)
        IgnorePointer(
          child: _buildVisualBackground(settings.onboardingStep),
        ),

        // 2. Interaction Blocker (Logic)
        _buildInteractionBlocker(settings.onboardingStep),

        // 3. Instruction Text (Speech Bubble)
        IgnorePointer(
          ignoring: settings.onboardingStep == 0 || settings.onboardingStep == 2,
          child: _buildInstruction(settings.onboardingStep),
        ),
      ],
    );
  }

  Widget _buildVisualBackground(int step) {
    // Step 1: Only gray out the buttons, no global dimming
    // Step 3 (Home): Only gray out the buttons
    // Step 3 (Constellation): NO dimming at all to highlight the star
    if (step == 3 && widget.isConstellationView) {
      return const SizedBox.shrink();
    }

    if (step == 1 || step == 3) {
      return Stack(
        children: [
          if (_addRect != null)
            Positioned.fromRect(
              rect: _addRect!.inflate(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          if (_constellationRect != null)
            Positioned.fromRect(
              rect: _constellationRect!.inflate(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
        ],
      );
    }

    // Step 0 and 2: Standard hole-in-dimming
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 0.7),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          if (_targetRect != null)
            Positioned.fromRect(
              rect: _targetRect!.inflate(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(step == 0 ? 30 : 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstruction(int step) {
    String message = '';
    bool showTail = false;
    double tailX = 0;
    Alignment alignment = Alignment.center;
    double verticalOffset = 0;

    switch (step) {
      case 0:
        message = 'ようこそ！振り返りに特化した日記アプリ「ホシログ」です。まずは右下のボタンを押して、今日の出来事を記録してみましょう';
        showTail = true;
        break;
      case 1:
        message = 'いいですね！この粒子はあなたの記録・振り返りの状況によって動きが変わります';
        alignment = Alignment.bottomCenter;
        verticalOffset = -140;
        break;
      case 2:
        message = '次に、こちらのボタンを押して、記録の一覧画面を開いてみましょう';
        showTail = true;
        break;
      case 3:
        message = 'ここにはあなたの出来事が星として灯ります。振り返ればさらに輝き、新たな取り組みをすれば星座のように繋がっていきます。';
        if (widget.isConstellationView) {
          alignment = Alignment.topCenter;
          verticalOffset = MediaQuery.of(context).padding.top + 60;
        } else {
          alignment = Alignment.center;
        }
        break;
    }

    if (showTail && _targetRect != null) {
      tailX = _targetRect!.center.dx;
    }

    return Stack(
      children: [
        if (showTail && _targetRect != null)
          _buildBubbleWithTail(message, tailX)
        else
          _buildPositionedBubble(message, alignment, verticalOffset),
      ],
    );
  }

  Widget _buildPositionedBubble(String message, Alignment alignment, double verticalOffset) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Transform.translate(
          offset: Offset(0, verticalOffset),
          child: _buildFrostedBubble(message, false, 0),
        ),
      ),
    );
  }

  Widget _buildBubbleWithTail(String message, double targetX) {
    final bubbleBottom = (_targetRect?.top ?? 0) - 24;
    
    return Positioned(
      bottom: MediaQuery.of(context).size.height - bubbleBottom,
      left: 20,
      right: 20,
      child: _buildFrostedBubble(message, true, targetX),
    );
  }

  Widget _buildFrostedBubble(String message, bool hasTail, double targetX) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: hasTail ? SpeechBubbleClipper(targetX: targetX) : null,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: hasTail ? null : BorderRadius.circular(24),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
        if (hasTail)
          Positioned.fill(
            child: CustomPaint(
              painter: SpeechBubbleBorderPainter(targetX: targetX),
            ),
          )
        else
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInteractionBlocker(int step) {
    if (step == 1 || step == 3) {
      return Positioned.fill(
        child: GestureDetector(
          onTap: () {
            if (step == 1) {
              ref.read(settingsProvider.notifier).updateOnboardingStep(2);
            } else if (step == 3) {
              ref.read(settingsProvider.notifier).setOnboardingSeen(true);
            }
          },
          behavior: HitTestBehavior.opaque,
        ),
      );
    }

    if (_targetRect == null) {
      return Positioned.fill(
        child: GestureDetector(
          onTap: () {},
          behavior: HitTestBehavior.opaque,
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final target = _targetRect!.inflate(8);

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: target.top,
          child: GestureDetector(onTap: () {}, behavior: HitTestBehavior.opaque),
        ),
        Positioned(
          top: target.bottom,
          left: 0,
          right: 0,
          height: screenHeight - target.bottom,
          child: GestureDetector(onTap: () {}, behavior: HitTestBehavior.opaque),
        ),
        Positioned(
          top: target.top,
          left: 0,
          width: target.left,
          height: target.height,
          child: GestureDetector(onTap: () {}, behavior: HitTestBehavior.opaque),
        ),
        Positioned(
          top: target.top,
          left: target.right,
          width: screenWidth - target.right,
          height: target.height,
          child: GestureDetector(onTap: () {}, behavior: HitTestBehavior.opaque),
        ),
      ],
    );
  }
}

class SpeechBubbleClipper extends CustomClipper<Path> {
  final double targetX;
  SpeechBubbleClipper({required this.targetX});

  @override
  Path getClip(Size size) {
    final path = Path();
    const radius = 24.0;
    double localX = (targetX - 20).clamp(radius + 20, size.width - radius - 20);

    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(radius),
    ));

    final tailPath = Path();
    tailPath.moveTo(localX - 20, size.height);
    tailPath.cubicTo(localX - 10, size.height, localX - 5, size.height + 15, localX, size.height + 15);
    tailPath.cubicTo(localX + 5, size.height + 15, localX + 10, size.height, localX + 20, size.height);
    tailPath.close();

    path.addPath(tailPath, Offset.zero);
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class SpeechBubbleBorderPainter extends CustomPainter {
  final double targetX;
  SpeechBubbleBorderPainter({required this.targetX});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final path = Path();
    const radius = 24.0;
    double localX = (targetX - 20).clamp(radius + 20, size.width - radius - 20);

    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(radius),
    ));

    final tailPath = Path();
    tailPath.moveTo(localX - 20, size.height);
    tailPath.cubicTo(localX - 10, size.height, localX - 5, size.height + 15, localX, size.height + 15);
    tailPath.cubicTo(localX + 5, size.height + 15, localX + 10, size.height, localX + 20, size.height);
    
    path.addPath(tailPath, Offset.zero);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
