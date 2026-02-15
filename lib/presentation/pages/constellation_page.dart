import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decision_tracker/domain/models/constellation_models.dart';
import 'package:decision_tracker/domain/providers/constellation_providers.dart';
import 'package:decision_tracker/domain/providers/app_providers.dart';
import 'package:decision_tracker/data/local/database.dart';
import '../widgets/decision_detail_sheet.dart';

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
      });
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
            colors: [Color(0xFF020617), Colors.black],
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
      // Tap on background - clear focus if not already clear
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
    setState(() {
      _selectedNodeId = null;
      _focusedChainId = null;
      _focusedChainNodes = [];
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
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'CONSTELLATION',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.white24, size: 20),
            onPressed: () {
               setState(() {
                  _initialized = false;
                  _revealedCount = 0;
                  _nodes = [];
               });
            },
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

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 220,
      child: PageView.builder(
        controller: _pageController,
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
          return _buildNodeCard(node);
        },
      ),
    );
  }

  Widget _buildNodeCard(ConstellationNode node) {
    final color = HSVColor.fromAHSV(1.0, node.hue, 0.7, 0.9).toColor();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  node.type.name.toUpperCase(),
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Text(
                '${node.date.month}/${node.date.day}',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            node.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton(
              onPressed: () => _showDetail(node),
              child: Text('READ MORE', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _showDetail(ConstellationNode node) async {
    Decision? decision;
    if (node.type == ConstellationNodeType.decision) {
      decision = node.originalData as Decision;
    } else {
      final allDecisions = await ref.read(allDecisionsProvider.future);
      // Use firstWhereOrNull to avoid crashes if data is missing
      decision = allDecisions.where((d) => d.id == node.chainId).firstOrNull;
    }

    if (mounted && decision != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DecisionDetailSheet(decision: decision!),
      );
    }
  }
}

class ConstellationPhysicsPainter extends CustomPainter {
  final List<ConstellationNode> nodes;
  final List<ConstellationEdge> edges;
  final String? selectedId;
  final int revealedCount;

  ConstellationPhysicsPainter({
    required this.nodes,
    required this.edges,
    this.selectedId,
    required this.revealedCount,
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

    // 2. Boundbox
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(Offset.zero & size, borderPaint);

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
    final double pulse = (math.sin(now.millisecondsSinceEpoch / 1000 * math.pi) + 1) / 2; // 0.0 to 1.0

    for (int i = 0; i < nodes.length; i++) {
      if (i >= revealedCount) continue;

      final node = nodes[i];
      final isSelected = node.id == selectedId;
      final bool isReviewed = node.isReviewed;
      final int score = node.score;
      
      // Thinking Lineage Color (Deterministic from Provider)
      // High saturation and value for a "poppy", vibrant look
      final Color baseColor = HSVColor.fromAHSV(1.0, node.hue, 0.9, 1.0).toColor();
      
      final ageHours = now.difference(node.date).inHours;
      final ageFactor = (1.0 - (ageHours / 168.0)).clamp(0.4, 1.0);
      
      // Luminosity Factor based on score (5-3-1)
      double luminosity = isReviewed 
          ? (score == 5 ? 1.6 : (score == 3 ? 1.1 : 0.7))
          : 0.3; // Seed luminosity

      // 1. Outer Halo (Large, very faint)
      final double haloOpacity = isReviewed 
          ? (0.15 * luminosity) // Toned down
          : (0.1 * pulse); 
          
      if (haloOpacity > 0.01) {
        final haloPaint = Paint()
          ..color = baseColor.withValues(alpha: haloOpacity * ageFactor)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * luminosity); // Reduced blur
        canvas.drawCircle(node.position, 18 * luminosity * ageFactor, haloPaint); // Reduced size
      }

      // 2. Inner Glow (Bright, centered)
      if (isReviewed || isSelected) {
        final glowPaint = Paint()
          ..color = baseColor.withValues(alpha: (isSelected ? 0.7 : 0.5 * luminosity) * ageFactor)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, (10 * luminosity) + (isSelected ? 5 : 0));
        canvas.drawCircle(node.position, (12 * luminosity) + (isSelected ? 5 : 0), glowPaint);
      }


      // 4. White Core (The hot center)
      final corePaint = Paint()..color = Colors.white.withValues(alpha: isReviewed ? 1.0 : 0.7);
      final double coreSize = (isReviewed ? (isSelected ? 4.0 : 3.0) : 1.5) * ageFactor;
      canvas.drawCircle(node.position, coreSize, corePaint);
      
      // 5. Category Colored Skin (Just around the core)
      if (isReviewed) {
        final skinPaint = Paint()
          ..color = baseColor.withValues(alpha: 0.8 * ageFactor)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(node.position, coreSize + 0.5, skinPaint);
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
