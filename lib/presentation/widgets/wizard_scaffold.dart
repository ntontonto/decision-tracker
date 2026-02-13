import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_design.dart';
import 'wizard_step_indicator.dart';

class WizardScaffold extends StatefulWidget {
  final int totalSteps;
  final int currentStep;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback onClose;
  final PageController pageController;
  final List<Widget> children;
  final Widget? bottomNavigationBar;
  final bool showErrorGlow;
  final ScrollController scrollController;
  final Function(int)? onPageChanged;

  const WizardScaffold({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.onBack,
    this.onNext,
    required this.onClose,
    required this.pageController,
    required this.children,
    this.bottomNavigationBar,
    this.showErrorGlow = false,
    required this.scrollController,
    this.onPageChanged,
  });

  @override
  State<WizardScaffold> createState() => WizardScaffoldState();
}

class WizardScaffoldState extends State<WizardScaffold> {
  bool _isPeeking = false;

  /// Animates the current page to "peek" at the next page and then return.
  /// This suggests to the user that there is more content and they can swipe.
  Future<void> peekNextPage() async {
    if (_isPeeking || !widget.pageController.hasClients) return;
    if (widget.currentStep >= widget.totalSteps - 1) return;

    setState(() => _isPeeking = true);
    try {
      final currentOffset = widget.pageController.offset;
      final peekOffset = currentOffset + 40.0; // Peek by 40 logical pixels

      await widget.pageController.animateTo(
        peekOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      
      await Future.delayed(const Duration(milliseconds: 100));

      await widget.pageController.animateTo(
        currentOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInCubic,
      );
    } finally {
      if (mounted) {
        setState(() => _isPeeking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: AppDesign.glassBlur, sigmaY: AppDesign.glassBlur),
      child: Material(
        color: Colors.transparent,
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          snap: true,
          builder: (context, sc) {
            return Container(
              decoration: BoxDecoration(
                color: AppDesign.glassBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(color: AppDesign.glassBorderColor, width: AppDesign.glassBorderWidth),
              ),
              child: Column(
                children: [
                  // Top Handle
                  SizedBox(
                    height: 32,
                    child: SingleChildScrollView(
                      controller: sc,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Header: Indicator & Close button
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      WizardStepIndicator(
                        currentStep: widget.currentStep,
                        totalSteps: widget.totalSteps,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: widget.onClose,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Main Content with Gestures
                  Expanded(
                    child: Stack(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapUp: (details) {
                            final x = details.localPosition.dx;
                            final width = MediaQuery.of(context).size.width;
                            if (x < width * 0.15) {
                              widget.onBack?.call();
                            } else if (x > width * 0.85) {
                              widget.onNext?.call();
                            } else {
                              // Tapping in the center (background) dismisses keyboard
                              FocusScope.of(context).unfocus();
                            }
                          },
                          onHorizontalDragEnd: (details) {
                            final velocity = details.primaryVelocity ?? 0;
                            if (velocity < -500) {
                              widget.onNext?.call();
                            } else if (velocity > 500) {
                              widget.onBack?.call();
                            }
                          },
                          child: PageView(
                            controller: widget.pageController,
                            onPageChanged: widget.onPageChanged,
                            physics: const NeverScrollableScrollPhysics(),
                            children: widget.children,
                          ),
                        ),
                        
                        // Error Glow
                        if (widget.showErrorGlow)
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            width: 15,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft,
                                    colors: [AppDesign.errorGlowColor, Colors.transparent],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Bottom Action Bar
                  if (widget.bottomNavigationBar != null) widget.bottomNavigationBar!,
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
