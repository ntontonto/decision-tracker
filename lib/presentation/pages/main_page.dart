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

              final curve = Curves.easeInOutQuart;
              final t = curve.transform(animation.value);

              return FadeTransition(
                opacity: animation,
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // perspective
                    ..rotateX((1.0 - t) * -0.35)
                    ..translate(0.0, (1.0 - t) * -100.0),
                  alignment: Alignment.center,
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
      body: Stack(
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
    );
  }
}
