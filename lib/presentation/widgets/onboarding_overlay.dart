import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/settings_provider.dart';
import '../../domain/providers/reaction_providers.dart'; // Added import

class OnboardingOverlay extends ConsumerStatefulWidget {
  final GlobalKey? addButtonKey;
  final GlobalKey? constellationButtonKey;
  final GlobalKey? backButtonKey; // Added backButtonKey
  final bool isConstellationView;

  const OnboardingOverlay({
    super.key,
    this.addButtonKey,
    this.constellationButtonKey,
    this.backButtonKey, // Added backButtonKey
    this.isConstellationView = false,
  });

  @override
  ConsumerState<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends ConsumerState<OnboardingOverlay> {
  Rect? _targetRect;
  Rect? _addRect;
  Rect? _constellationRect;
  Rect? _backRect; // Added _backRect

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

      Rect? newBackRect; // Added newBackRect calculation
      if (widget.backButtonKey != null) {
        newBackRect = _getWidgetRect(widget.backButtonKey!);
      }
      
      Rect? newTargetRect;
      if (step == 2) {
        newTargetRect = newAddRect;
      } else if (step == 4) {
        newTargetRect = newConstellationRect;
      } else if (step == 6) {
        newTargetRect = newBackRect;
      } else {
        newTargetRect = null;
      }

      if (newTargetRect != _targetRect || newAddRect != _addRect || newConstellationRect != _constellationRect || newBackRect != _backRect) { // Updated condition
        setState(() {
          _targetRect = newTargetRect;
          _addRect = newAddRect;
          _constellationRect = newConstellationRect;
          _backRect = newBackRect; // Updated _backRect
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

    // On Home screen, hide constellation-specific steps (5, 6)
    if (!widget.isConstellationView && (settings.onboardingStep == 5 || settings.onboardingStep == 6)) {
      return const SizedBox.shrink();
    }
    // On Constellation screen, hide home-specific steps (0, 1, 2, 3, 4, 7)
    if (widget.isConstellationView && (settings.onboardingStep < 5 || settings.onboardingStep == 7)) {
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

        // 3. Instruction Text (Premium Card)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ));
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: offsetAnimation,
                child: child,
              ),
            );
          },
          child: IgnorePointer(
            key: ValueKey(settings.onboardingStep),
            ignoring: settings.onboardingStep == 0 || settings.onboardingStep == 2,
            child: _buildInstruction(settings.onboardingStep),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualBackground(int step) {
    // Step 5 (Constellation - Concept): NO dimming at all to highlight the star
    if (step == 5 && widget.isConstellationView) {
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
    String tag = 'INFO';
    String title = '';
    String message = '';
    bool showTail = false;
    double tailX = 0;
    Alignment alignment = Alignment.center;
    double verticalOffset = 0;

    switch (step) {
      case 0:
        title = 'ようこそ';
        message = '振り返りに特化した日記アプリ「ホシログ」です。';
        break;
      case 1:
        title = 'ホシログの想い';
        message = 'このアプリでは、今日あった出来事を振り返る「余白」を作ります。';
        break;
      case 2:
        title = '最初の記録';
        message = 'きょうのできごとで、何か記憶に残ったものはありますか？右下のボタンから登録してみましょう。';
        showTail = true;
        break;
      case 3:
        title = '記録の粒子';
        message = 'いいですね！この粒子はあなたの記録・振り返りの状況によって動きが変わります。';
        alignment = Alignment.bottomCenter;
        verticalOffset = -140;
        break;
      case 4:
        title = '星座の一覧';
        message = '次に、こちらのボタンを押して、記録の一覧画面を開いてみましょう。';
        showTail = true;
        break;
      case 5:
        title = '学びの星座';
        message = 'ここにはあなたの出来事が星として灯ります。振り返ればさらに輝き、新たな取り組みをすれば星座のように繋がっていきます。';
        if (widget.isConstellationView) {
          alignment = Alignment.topCenter;
          verticalOffset = MediaQuery.of(context).padding.top + 20;
        }
        break;
      case 6:
        title = 'ホームへの帰還';
        message = '右下のボタンを押すことでホームに戻れます。';
        if (widget.isConstellationView) {
          alignment = Alignment.topCenter;
          verticalOffset = MediaQuery.of(context).padding.top + 60;
          showTail = true;
        }
        break;
      case 7:
        title = '自分との対話';
        message = 'おかえりなさい！これですべての準備が整いました。日々の小さな出来事も、振り返ることでかけがえのない経験に変わります。あなたの物語を、星として灯し続けていきましょう。';
        alignment = Alignment.center;
        tag = 'FINISH';
        break;
    }

    if (showTail && _targetRect != null) {
      tailX = _targetRect!.center.dx;
    }

    return Stack(
      children: [
        if (showTail && _targetRect != null)
          _buildCardWithTail(tag, title, message, tailX)
        else
          _buildPositionedCard(step, tag, title, message, alignment, verticalOffset),
      ],
    );
  }

  Widget _buildPositionedCard(int step, String tag, String title, String message, Alignment alignment, double verticalOffset) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Transform.translate(
          offset: Offset(0, verticalOffset),
          child: OnboardingCard(
            tag: tag,
            title: title,
            message: message,
            showHint: true,
            padding: (step == 3 || step == 5) ? const EdgeInsets.symmetric(vertical: 16, horizontal: 24) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCardWithTail(String tag, String title, String message, double targetX) {
    final bubbleBottom = (_targetRect?.top ?? 0) - 24;
    
    return Positioned(
      bottom: MediaQuery.of(context).size.height - bubbleBottom,
      left: 20,
      right: 20,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          OnboardingCard(
            tag: tag,
            title: title,
            message: message,
            hasTail: true,
            targetX: targetX,
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionBlocker(int step) {
    if (step == 0 || step == 1 || step == 3 || step == 5 || step == 7) {
      return Positioned.fill(
        child: GestureDetector(
          onTap: () {
            if (step == 0) {
              ref.read(settingsProvider.notifier).updateOnboardingStep(1);
            } else if (step == 1) {
              ref.read(settingsProvider.notifier).updateOnboardingStep(2);
            } else if (step == 3) {
              ref.read(settingsProvider.notifier).updateOnboardingStep(4);
            } else if (step == 5) {
              ref.read(settingsProvider.notifier).updateOnboardingStep(6);
            } else if (step == 7) {
              ref.read(settingsProvider.notifier).setOnboardingSeen(true);
              ref.read(reactionProvider.notifier).trigger(ParticleReaction.celebrate);
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

class OnboardingCard extends StatelessWidget {
  final String tag;
  final String title;
  final String message;
  final bool showHint;
  final bool hasTail;
  final double? targetX;
  final EdgeInsetsGeometry? padding;

  const OnboardingCard({
    super.key,
    required this.tag,
    required this.title,
    required this.message,
    this.showHint = false,
    this.hasTail = false,
    this.targetX,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Shadow Blur Layer
        if (!hasTail)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 40,
                    spreadRadius: -10,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
            ),
          ),

        // 2. Glass Body
        ClipPath(
          clipper: (hasTail && targetX != null) ? OnboardingCardClipper(targetX: targetX!) : null,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: padding ?? const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: hasTail ? null : BorderRadius.circular(28),
                border: hasTail ? null : Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Body
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (showHint) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, size: 14, color: Colors.white.withValues(alpha: 0.4)),
                        const SizedBox(width: 8),
                        Text(
                          '画面をタップして進む',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // 3. Border Glow for Tail
        if (hasTail && targetX != null)
          Positioned.fill(
            child: CustomPaint(
              painter: OnboardingCardBorderPainter(targetX: targetX!),
            ),
          ),
      ],
    );
  }
}

class OnboardingCardClipper extends CustomClipper<Path> {
  final double targetX;
  OnboardingCardClipper({required this.targetX});

  @override
  Path getClip(Size size) {
    final path = Path();
    const radius = 28.0;
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

class OnboardingCardBorderPainter extends CustomPainter {
  final double targetX;
  OnboardingCardBorderPainter({required this.targetX});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final path = Path();
    const radius = 28.0;
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
