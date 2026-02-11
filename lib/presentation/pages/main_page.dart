import 'package:flutter/material.dart';
import 'particle_simulation_page.dart';
import '../widgets/home_overlay_ui.dart';
import '../widgets/app_sidebar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      drawer: const AppSidebar(),
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
          
          // Overlay UI: Proposal Card + FAB
          const HomeOverlayUI(),
        ],
      ),
    );
  }
}
