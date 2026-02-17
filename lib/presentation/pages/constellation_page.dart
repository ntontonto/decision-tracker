import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decision_tracker/domain/models/constellation_models.dart';
import 'package:decision_tracker/data/local/database.dart';
import 'package:decision_tracker/domain/providers/constellation_providers.dart';
import 'package:decision_tracker/domain/providers/app_providers.dart';
import '../widgets/decision_detail_sheet.dart';
import '../widgets/constellation_node_card.dart';

class ConstellationPage extends ConsumerStatefulWidget {
  const ConstellationPage({super.key});

  @override
  ConsumerState<ConstellationPage> createState() => _ConstellationPageState();
}

class _ConstellationPageState extends ConsumerState<ConstellationPage> with TickerProviderStateMixin {
  late Ticker _ticker;
  final TransformationController _transformationController = TransformationController();

  // Animation State
  late AnimationController _revelationController;
  int _revealedCount = 0;
  bool _showGalaxy = false;
  
  // Navigation State
  String? _selectedNodeId;
  String? _focusedChainId;
  List<ConstellationNode> _focusedChainNodes = [];
  late PageController _pageController;
  bool _isAnimatingCamera = false;
  bool _isCardExpanded = false;
  bool _isCardVisible = false;
  
  // Animation state for newly reviewed stars
  final Map<String, double> _glowProgress = {};
  
  // Simulation State
  List<ConstellationNode> _nodes = [];
  List<ConstellationEdge> _edges = [];
  Size _worldSize = const Size(2000, 2000);
  bool _initialized = false;

  Offset _lastPointerDownPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();

    _pageController = PageController();
    _revelationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _revelationController.addListener(() {
      if (_nodes.isEmpty) return;
      final count = (Curves.easeIn.transform(_revelationController.value) * _nodes.length).floor();
      if (count != _revealedCount) {
        setState(() => _revealedCount = count);
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _transformationController.dispose();
    _pageController.dispose();
    _revelationController.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_nodes.isEmpty) return;

    if (mounted) {
      setState(() {
        _applyPhysics();
        _updateAnimations();
      });
    }
  }

  void _updateAnimations() {
    final toRemove = <String>[];
    _glowProgress.forEach((id, progress) {
      final newProgress = progress - 0.02; // Decrease over ~50 ticks (1 sec at 60fps)
      if (newProgress <= 0) {
        toRemove.add(id);
      } else {
        _glowProgress[id] = newProgress;
      }
    });
    for (final id in toRemove) {
      _glowProgress.remove(id);
    }
  }

  void _applyPhysics() {
    const double friction = 0.98;
    const double springK = 0.03; // Pull strength
    const double restLength = 80.0; // Desired distance
    const double repulsionK = 50.0; // Avoid overlapping

    // 1. Edge Constraints (Springs)
    for (final edge in _edges) {
      final fromIdx = _nodes.indexWhere((n) => n.id == edge.fromId);
      final toIdx = _nodes.indexWhere((n) => n.id == edge.toId);
      if (fromIdx == -1 || toIdx == -1) continue;

      final n1 = _nodes[fromIdx];
      final n2 = _nodes[toIdx];
      
      final diff = n2.position - n1.position;
      final dist = diff.distance;
      if (dist == 0) continue;

      final force = (dist - restLength) * springK;
      final unit = diff / dist;
      
      final forceOffset = unit * force;

      // Update velocities
      _nodes[fromIdx] = _nodes[fromIdx].copy(velocity: _nodes[fromIdx].velocity + forceOffset);
      _nodes[toIdx] = _nodes[toIdx].copy(velocity: _nodes[toIdx].velocity - forceOffset);
    }

    // 2. Global Repulsion (Prevent clumps)
    for (int i = 0; i < _nodes.length; i++) {
       for (int j = i + 1; j < _nodes.length; j++) {
          final diff = _nodes[j].position - _nodes[i].position;
          final distSq = diff.distanceSquared;
          if (distSq < 10000 && distSq > 1) { // Within range
             final force = repulsionK / distSq;
             final unit = diff / math.sqrt(distSq);
             _nodes[i] = _nodes[i].copy(velocity: _nodes[i].velocity - unit * force);
             _nodes[j] = _nodes[j].copy(velocity: _nodes[j].velocity + unit * force);
          }
       }
    }

    // 3. Update Positions & Boundaries
    for (int i = 0; i < _nodes.length; i++) {
      var vel = _nodes[i].velocity * friction;
      var pos = _nodes[i].position + vel;

      // Boundary Bounce
      if (pos.dx < 50 || pos.dx > _worldSize.width - 50) {
        vel = Offset(-vel.dx * 0.8, vel.dy);
        pos = Offset(pos.dx.clamp(50, _worldSize.width - 50), pos.dy);
      }
      if (pos.dy < 50 || pos.dy > _worldSize.height - 50) {
        vel = Offset(vel.dx, -vel.dy * 0.8);
        pos = Offset(pos.dx, pos.dy.clamp(50, _worldSize.height - 50));
      }

      _nodes[i] = _nodes[i].copy(position: pos, velocity: vel);
    }
  }

  void _initializeViewport(Size worldSize) {
    if (_initialized) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Center on the world
    final xTranslation = (screenWidth - worldSize.width * 0.4) / 2;
    final yTranslation = (screenHeight - worldSize.height * 0.4) / 2;

    _transformationController.value = Matrix4.identity()
      ..setTranslationRaw(xTranslation, yTranslation, 0)
      ..scale(0.4, 0.4, 1.0);

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final graphAsync = ref.watch(constellationProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: graphAsync.when(
        data: (graph) {
          if (_nodes.isEmpty && graph.nodes.isNotEmpty) {
            // Sort nodes by date for sequential revelation
            final sortedNodes = List<ConstellationNode>.from(graph.nodes)
              ..sort((a, b) => a.date.compareTo(b.date));
            
            _nodes = sortedNodes;
            _edges = List.from(graph.edges);
            _worldSize = graph.totalSize;

            // Warm-up simulation
            for (int i = 0; i < 60; i++) {
              _applyPhysics();
            }

            // Trigger sequence
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _showGalaxy = true);
                _revelationController.forward(from: 0.0);
              }
            });
          } else if (_nodes.isNotEmpty && graph.nodes.isNotEmpty) {
            // Reactive Sync: Update existing nodes without re-shuffling layout
            bool changed = false;
            for (final newNode in graph.nodes) {
              final existingIdx = _nodes.indexWhere((n) => n.id == newNode.id);
              if (existingIdx != -1) {
                final oldNode = _nodes[existingIdx];
                if (oldNode.isReviewed != newNode.isReviewed || oldNode.score != newNode.score) {
                  _nodes[existingIdx] = oldNode.copy(
                    isReviewed: newNode.isReviewed,
                    score: newNode.score,
                  );
                  
                  // Trigger glow if newly reviewed
                  if (!oldNode.isReviewed && newNode.isReviewed) {
                    _glowProgress[newNode.id] = 1.0;
                  }
                  changed = true;
                }
              }
            }
            if (changed) {
              // We need to trigger a repaint
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            }
          }
          
          WidgetsBinding.instance.addPostFrameCallback((_) => _initializeViewport(_worldSize));

          return Stack(
            children: [
              _buildSpaceBackground(),
              _buildInteractionLayer(),
              // Passive Interaction Layer: Handle taps without blocking IV scrolls
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) => _lastPointerDownPos = event.position,
                  onPointerUp: (event) {
                    final distance = (event.position - _lastPointerDownPos).distance;
                    if (distance < 10) { // Genuine tap, not a scroll
                      final viewportPos = event.localPosition;
                      final scenePos = _transformationController.toScene(viewportPos);
                      _handleTapAt(scenePos, viewportPos);
                    }
                  },
                ),
              ),
              _buildHeader(),
              _buildDetailOverlay(),
              if (!_showGalaxy || _revelationController.isAnimating) 
                _buildOverlayInstructions(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white24)),
        error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildSpaceBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF0F172A), // Deep Navy
              Color(0xFF020617), // Very Dark charcoal-purple
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionLayer() {
    return AnimatedOpacity(
      opacity: _showGalaxy ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeIn,
      child: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(2000),
        minScale: 0.1,
        maxScale: 2.5,
        child: CustomPaint(
          size: _worldSize,
          painter: ConstellationPhysicsPainter(
            nodes: _nodes,
            edges: _edges,
            selectedId: _selectedNodeId,
            revealedCount: _revealedCount,
            glowProgress: Map.from(_glowProgress),
          ),
        ),
      ),
    );
  }

  void _handleTapAt(Offset scenePos, Offset viewportPos) {
    if (_revelationController.isAnimating) return;

    final hitNode = _findNodeAt(scenePos);
    
    if (hitNode != null) {
      _focusNode(hitNode);
    } else {
      // Tap on background
      if (_selectedNodeId != null) {
        _clearFocus();
      }
    }
  }

  void _focusNode(ConstellationNode node) {
    setState(() {
      _selectedNodeId = node.id;
      if (_focusedChainId != node.chainId) {
        _focusedChainId = node.chainId;
        _focusedChainNodes = _nodes
            .where((n) => n.chainId == node.chainId)
            .toList()
          ..sort((a, b) => a.generation.compareTo(b.generation));
      }
      _isCardExpanded = false;
      _isCardVisible = true;
    });

    // Sync PageView
    final pageIndex = _focusedChainNodes.indexWhere((n) => n.id == node.id);
    if (pageIndex != -1 && _pageController.hasClients && _pageController.page?.round() != pageIndex) {
      _pageController.animateToPage(
        pageIndex, 
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut,
      );
    }

    _animateCameraToNode(node);
  }

  void _clearFocus() {
    if (!_isCardVisible) return;
    
    setState(() {
      _isCardVisible = false;
      _isCardExpanded = false;
    });
    
    // Delay clearing the data to allow animation to complete
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_isCardVisible) {
        setState(() {
          _selectedNodeId = null;
          _focusedChainId = null;
          _focusedChainNodes = [];
        });
      }
    });
  }

  void _animateCameraToNode(ConstellationNode node) {
    _isAnimatingCamera = true;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const targetScale = 0.8;

    final targetX = screenWidth / 2 - node.position.dx * targetScale;
    final targetY = screenHeight / 2 - node.position.dy * targetScale;

    final endMatrix = Matrix4.identity()
      ..setTranslationRaw(targetX, targetY, 0)
      ..scale(targetScale, targetScale, 1.0);

    final startMatrix = _transformationController.value;
    final animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final matrixTween = Matrix4Tween(begin: startMatrix, end: endMatrix);
    animation.addListener(() {
      _transformationController.value = matrixTween.evaluate(CurvedAnimation(
        parent: animation,
        curve: Curves.fastOutSlowIn,
      ));
    });
    
    animation.forward().then((_) {
      _isAnimatingCamera = false;
      animation.dispose();
    });
  }

  ConstellationNode? _findNodeAt(Offset scenePos) {
    // Check revealed nodes only
    for (int i = 0; i < _revealedCount && i < _nodes.length; i++) {
      final node = _nodes[i];
      final distance = (node.position - scenePos).distance;
      if (distance < 70) {
        return node;
      }
    }
    return null;
  }

  Widget _buildHeader() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        children: [
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.blur_on, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Return to Vortex',
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayInstructions() {
    return Positioned(
      bottom: 60,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: _showGalaxy ? 1.0 : 0.0,
          duration: const Duration(seconds: 1),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 1, color: Colors.white24),
              SizedBox(height: 16),
              Text(
                'COLLECTING MEMORIES...',
                style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDetailOverlay() {
    if (_focusedChainNodes.isEmpty) return const SizedBox.shrink();

    final screenHeight = MediaQuery.of(context).size.height;
    final collapsedHeight = 220.0;
    final expandedHeight = screenHeight * 0.7;
    final currentHeight = _isCardExpanded ? expandedHeight : collapsedHeight;

    final isShowing = _isCardVisible;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      bottom: isShowing ? 0 : -collapsedHeight,
      left: 0,
      right: 0,
      height: currentHeight,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        opacity: isShowing ? 1.0 : 0.0,
        child: GestureDetector(
        onTap: () {
          if (!_isCardExpanded) {
            setState(() => _isCardExpanded = true);
          }
        },
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity! < -500) {
            // Swipe Up
            setState(() => _isCardExpanded = true);
          } else if (details.primaryVelocity! > 500) {
            // Swipe Down
            if (_isCardExpanded) {
              setState(() => _isCardExpanded = false);
            } else {
              _clearFocus();
            }
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.0),
                Colors.black.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(), // Always allow horizontal swiping
            itemCount: _focusedChainNodes.length,
            onPageChanged: (index) {
              if (!_isAnimatingCamera) {
                _animateCameraToNode(_focusedChainNodes[index]);
                setState(() {
                   _selectedNodeId = _focusedChainNodes[index].id;
                });
              }
            },
            itemBuilder: (context, index) {
              final node = _focusedChainNodes[index];
              return ConstellationNodeCard(
                node: node,
                isExpanded: _isCardExpanded,
              );
            },
          ),
        ),
      ),
    ),
  );
}


}

class ConstellationPhysicsPainter extends CustomPainter {
  final List<ConstellationNode> nodes;
  final List<ConstellationEdge> edges;
  final String? selectedId;
  final int revealedCount;
  final Map<String, double> glowProgress;

  ConstellationPhysicsPainter({
    required this.nodes,
    required this.edges,
    this.selectedId,
    required this.revealedCount,
    required this.glowProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Static Starfield
    final random = math.Random(42);
    final bgStarPaint = Paint()..color = Colors.white.withValues(alpha: 0.1);
    for (int i = 0; i < 300; i++) {
       canvas.drawCircle(
         Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
         random.nextDouble() * 1.5,
         bgStarPaint,
       );
    }


    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final highlightLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 3. Edges
    for (final edge in edges) {
      final fromIdx = nodes.indexWhere((n) => n.id == edge.fromId);
      final toIdx = nodes.indexWhere((n) => n.id == edge.toId);
      if (fromIdx == -1 || toIdx == -1) continue;
      
      // Only draw if both nodes are revealed
      if (fromIdx >= revealedCount || toIdx >= revealedCount) continue;

      final from = nodes[fromIdx];
      final to = nodes[toIdx];

      final isHighlighted = (selectedId == from.id || selectedId == to.id);
      
      if (isHighlighted) {
         canvas.drawLine(from.position, to.position, highlightLinePaint);
      } else {
         canvas.drawLine(from.position, to.position, linePaint);
      }
    }

    // 4. Nodes
    final now = DateTime.now();

    for (int i = 0; i < nodes.length; i++) {
      if (i >= revealedCount) continue;

      final node = nodes[i];
      final isSelected = node.id == selectedId;
      final bool isReviewed = node.isReviewed;
      final int score = node.score;
      
      // Thinking Lineage Color (Deterministic from Provider)
      // Drop Candy: High saturation (0.85) and max value (1.0)
      final Color baseColor = HSVColor.fromAHSV(1.0, node.hue, 0.85, 1.0).toColor();
      
      final ageHours = now.difference(node.date).inHours;
      final ageFactor = (1.0 - (ageHours / 168.0)).clamp(0.4, 1.0);
      
      // Luminosity Factor based on score (5-3-1)
      // Unreviewed nodes now match the base luminosity of score 1 (0.7)
      double luminosity = isReviewed 
          ? (score == 5 ? 1.6 : (score == 3 ? 1.1 : 0.7))
          : 1.1; // Balanced seed luminosity (matches score 3)

      // Time and Star-specific Randoms
      final double time = now.millisecondsSinceEpoch / 1000.0;
      final int seed = node.id.hashCode;
      final random = math.Random(seed);
      final double starDir = random.nextBool() ? 1.0 : -1.0;
      final double starSpeedMult = 0.7 + (random.nextDouble() * 0.8);

      // Flicker Factor for unreviewed nodes (Staccato / Broken Bulb)
      double flickerFactor = 1.0;
      if (!isReviewed) {
        final double t = time + (seed % 100);
        // Base irregular wobble
        double wobble = (math.sin(t * 2.5).abs() * 0.6) + (math.sin(t * 15.0).abs() * 0.2);
        
        // Sudden sharp "on/off" flickers (Broken bulb effect)
        // High frequency noise-like oscillation
        final double staccato = math.sin(t * 30.0) * math.sin(t * 47.0);
        if (staccato > 0.5) {
          wobble *= 0.2; // Sharp dimming
        } else if (staccato < -0.85) {
          wobble = 0.02; // Almost total blackout
        }

        // Periodic "power failure" (Deep fade every few seconds)
        final double powerPulse = (math.sin(t * 0.6) + 1.0) / 2.0; 
        if (powerPulse < 0.25) {
           wobble *= (powerPulse * 4.0).clamp(0.1, 1.0);
        }

        flickerFactor = (wobble + 0.2).clamp(0.01, 1.0);
      }

      // 1. Concentric Rings (Modern "Drop Candy" Style)
      final double localPulse = (math.sin((time + (seed % 100)) * (math.pi + (seed % 10) * 0.1)) + 1) / 2;
      final double ringOpacityFactor = ageFactor * (isReviewed ? 1.0 : (localPulse * 0.5 * flickerFactor));
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      // Orbital Satellites Count based on score
      // 5 pt -> 3 satellites, 3 pt -> 2 satellites, 1 pt/seed -> 1 satellite
      final int satelliteCount = node.isReviewed 
          ? (node.score == 5 ? 3 : (node.score == 3 ? 2 : 1)) 
          : 1;

      // Outer Ring
      final double outerRadius = 18 * luminosity * ageFactor;
      ringPaint.color = baseColor.withValues(alpha: 0.15 * ringOpacityFactor);
      canvas.drawCircle(node.position, outerRadius, ringPaint);

      final satellitePaint = Paint()..color = Colors.white.withValues(
        alpha: 0.6 * ringOpacityFactor * (isReviewed ? 1.0 : flickerFactor)
      );

      // Draw Outer Satellites
      for (int i = 0; i < satelliteCount; i++) {
        final double offset = (i * (math.pi * 2 / satelliteCount)) + (seed % 100);
        final double angle = (time * 0.8 * starSpeedMult * starDir) + offset;
        final Offset satellitePos = node.position + Offset(
          math.cos(angle) * outerRadius,
          math.sin(angle) * outerRadius,
        );
        canvas.drawCircle(satellitePos, 0.8, satellitePaint);
      }

      if (isReviewed) {
        // Middle ring for reviewed nodes
        final double middleRadius = 12 * luminosity * ageFactor;
        ringPaint.color = baseColor.withValues(alpha: 0.3 * ringOpacityFactor);
        canvas.drawCircle(node.position, middleRadius, ringPaint);

        // Inner Satellites (sharing same direction but faster)
        for (int i = 0; i < (satelliteCount > 1 ? 1 : 0); i++) {
          final double offset = (seed % 50).toDouble();
          final double angle = (time * 1.5 * starSpeedMult * starDir) + offset;
          final Offset satellitePos = node.position + Offset(
            math.cos(angle) * middleRadius,
            math.sin(angle) * middleRadius,
          );
          canvas.drawCircle(satellitePos, 0.6, satellitePaint);
        }
      }

      // 2. Inner Ring / Glow (Sharp)
      if (isReviewed || isSelected) {
        final innerGlowPaint = Paint()
          ..color = baseColor.withValues(alpha: (isSelected ? 0.4 : 0.25 * luminosity) * ageFactor)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(node.position, (isSelected ? 10.0 : 8.0) * luminosity, innerGlowPaint);
      }


      // 4. White Core with Candy Highlight (Slightly larger for visibility)
      final double coreSize = (isReviewed ? (isSelected ? 4.5 : 3.5) : 6.4) * ageFactor;
      
      // Main Core
      final corePaint = Paint()..color = isReviewed 
          ? baseColor 
          : baseColor.withValues(alpha: 0.6 * flickerFactor);
      canvas.drawCircle(node.position, coreSize, corePaint);
      
      // Glossy Highlight (White, slightly offset)
      final highlightPaint = Paint()..color = Colors.white.withValues(
        alpha: (isReviewed ? 0.8 : 0.4 * flickerFactor)
      );
      canvas.drawCircle(
        node.position - Offset(coreSize * 0.3, coreSize * 0.3), 
        coreSize * 0.4, 
        highlightPaint
      );

      // 5. Glow Effect (Dynamic)
      final double glow = glowProgress[node.id] ?? 0.0;
      if (glow > 0) {
        final double glowRadius = coreSize * (1.0 + glow * 4.0);
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: glow * 0.8)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0 * glow);
        
        canvas.drawCircle(node.position, glowRadius, glowPaint);
        
        // Secondary outer ring for the pulse
        final pulsePaint = Paint()
          ..color = baseColor.withValues(alpha: glow * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(node.position, coreSize * (2.0 + glow * 6.0), pulsePaint);
      }

      // 6. White Hot Center (Internal, sharp)
      if (isReviewed) {
        final centerPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
        canvas.drawCircle(node.position, coreSize * 0.3, centerPaint);
      }

      // 6. Interaction Ring
      if (isSelected) {
        final ringPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;
        canvas.drawCircle(node.position, (coreSize + 8) * ageFactor, ringPaint);
      }
    }
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
