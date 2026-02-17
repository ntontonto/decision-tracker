import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/reaction_providers.dart';
import 'constellation_page.dart';
import 'particle_simulation_page.dart';
import '../widgets/home_overlay_ui.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/success_notification.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _navigateToConstellation() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ConstellationPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Sync Warp State with animation progress
          final warpNotifier = ref.read(warpProvider.notifier);
          
          animation.addStatusListener((status) {
            if (status == AnimationStatus.dismissed) {
              warpNotifier.reset();
            }
          });

          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              WarpType type = WarpType.none;
              switch (animation.status) {
                case AnimationStatus.forward:
                  type = WarpType.entering;
                  break;
                case AnimationStatus.reverse:
                  type = WarpType.exiting;
                  break;
                case AnimationStatus.completed:
                  type = WarpType.holding;
                  break;
                case AnimationStatus.dismissed:
                  type = WarpType.none;
                  break;
              }
              
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  warpNotifier.setWarp(type, animation.value);
                }
              });

              final double t = Curves.easeInOutExpo.transform(animation.value);

              return FadeTransition(
                opacity: animation,
                child: Transform.scale(
                  scale: 0.8 + (t * 0.2), // Zoom in from 0.8 to 1.0
                  child: child,
                ),
              );
            },
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 1400),
        reverseTransitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      drawer: const AppSidebar(),
      resizeToAvoidBottomInset: false, // Prevents elements from jumping when keyboard appears
      body: Consumer(
        builder: (context, ref, child) {
          final warp = ref.watch(warpProvider);
          final double t = Curves.easeInOutExpo.transform(warp.factor);
          
          double scale = 1.0;
          double opacity = 1.0;
          
          if (warp.type == WarpType.entering) {
            scale = 1.0 + (t * 0.5); // Expand up to 1.5x
            opacity = (1.0 - t).clamp(0.0, 1.0);
          } else if (warp.type == WarpType.exiting) {
            scale = 1.0 + (t * 0.5); // Scale back from 1.5x
            opacity = (1.0 - t).clamp(0.0, 1.0);
          } else if (warp.type == WarpType.holding) {
            scale = 1.5;
            opacity = 0.0;
          }

          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          );
        },
        child: Stack(
          children: [
            // Background: Particle Simulation
            const ParticleSimulationPage(),
  
            // Floating Hamburger Menu Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white, size: 32),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
            
            // Constellation Navigation Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                onPressed: _navigateToConstellation,
                tooltip: 'Go to Constellation',
              ),
            ),
  
            // Overlay UI: Proposal Card + FAB
            const HomeOverlayUI(),
  
            // Success Notification Toast (TOPMOST Layer)
            const SuccessNotification(),
          ],
        ),
      ),
    );
  }
}
