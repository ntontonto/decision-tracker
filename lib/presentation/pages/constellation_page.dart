import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:decision_tracker/domain/models/constellation_models.dart';
import 'package:decision_tracker/domain/providers/constellation_providers.dart';
import 'package:decision_tracker/domain/providers/app_providers.dart';
import 'package:decision_tracker/presentation/pages/decision_list_page.dart';
import 'package:decision_tracker/data/local/database.dart';

class ConstellationPage extends ConsumerStatefulWidget {
  const ConstellationPage({super.key});

  @override
  ConsumerState<ConstellationPage> createState() => _ConstellationPageState();
}

class _ConstellationPageState extends ConsumerState<ConstellationPage> with TickerProviderStateMixin {
  late Ticker _ticker;
  final TransformationController _transformationController = TransformationController();
  
  // Simulation State
  List<ConstellationNode> _nodes = [];
  List<ConstellationEdge> _edges = [];
  String? _selectedNodeId;
  String? _draggedNodeId;
  Size _worldSize = const Size(2000, 2000);
  bool _initialized = false;
  bool _showGalaxy = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _transformationController.dispose();
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
      if (_nodes[i].id == _draggedNodeId) {
        // Dragged node doesn't follow normal physics
        continue;
      }

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
      ..scale(0.4);

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
            _nodes = List.from(graph.nodes);
            _edges = List.from(graph.edges);
            _worldSize = graph.totalSize;

            // Warm-up simulation to avoid initial "explosion" or jitter
            for (int i = 0; i < 60; i++) {
              _applyPhysics();
            }

            // Trigger fade in
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _showGalaxy = true);
            });
          }
          
          WidgetsBinding.instance.addPostFrameCallback((_) => _initializeViewport(_worldSize));

          return Stack(
            children: [
              _buildSpaceBackground(),
              _buildInteractionLayer(),
              _buildHeader(),
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
      child: Listener(
        onPointerDown: (event) {
          // Detect node hit early to disable IV panning.
          // CRITICAL: Listener localPosition is in VIEWPORT space, 
          // must convert to SCENE space using transformationController.
          final scenePos = _transformationController.toScene(event.localPosition);
          final hitNode = _findNodeAt(scenePos);
          if (hitNode != null) {
            setState(() {
              _draggedNodeId = hitNode.id;
            });
          }
        },
        child: InteractiveViewer(
          transformationController: _transformationController,
          boundaryMargin: const EdgeInsets.all(2000),
          minScale: 0.1,
          maxScale: 2.5,
          // Disable panning while dragging a node
          panEnabled: _draggedNodeId == null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) => _handlePanStart(details),
            onPanUpdate: (details) => _handlePanUpdate(details),
            onPanEnd: (details) => _handlePanEnd(details),
            onTapDown: (details) => _handleTap(details),
            child: CustomPaint(
              size: _worldSize,
              painter: ConstellationPhysicsPainter(
                nodes: _nodes,
                edges: _edges,
                selectedId: _selectedNodeId,
                draggedId: _draggedNodeId,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(TapDownDetails details) {
    // details.localPosition is already in scene coordinate because GestureDetector 
    // is a child of InteractiveViewer (the CustomPaint is its size)
    final worldPos = details.localPosition;
    final hitNode = _findNodeAt(worldPos);
    if (hitNode != null) {
      setState(() => _selectedNodeId = hitNode.id);
      _showDetail(hitNode);
    } else {
      setState(() => _selectedNodeId = null);
    }
  }

  void _handlePanStart(DragStartDetails details) {
    final worldPos = details.localPosition;
    final hitNode = _findNodeAt(worldPos);
    if (hitNode != null) {
      setState(() {
        _draggedNodeId = hitNode.id;
      });
    }
  }

  ConstellationNode? _findNodeAt(Offset scenePos) {
    // Return the node closest to the position within hit radius
    for (final node in _nodes) {
      if ((node.position - scenePos).distance < 70) {
        return node;
      }
    }
    return null;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_draggedNodeId == null) return;
    
    final worldPos = details.localPosition;
    final idx = _nodes.indexWhere((n) => n.id == _draggedNodeId);
    if (idx != -1) {
      setState(() {
        _nodes[idx] = _nodes[idx].copy(position: worldPos, velocity: Offset.zero);
      });
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_draggedNodeId != null) {
      final idx = _nodes.indexWhere((n) => n.id == _draggedNodeId);
      if (idx != -1) {
        setState(() {
          // Pass the release velocity to the node for physical "throw" effect
          // Note: velocity is in pixels/sec, our simulation uses roughly pixels/frame (friction based)
          final releaseVel = details.velocity.pixelsPerSecond / 60.0;
          _nodes[idx] = _nodes[idx].copy(velocity: releaseVel);
        });
      }
    }
    setState(() {
      _draggedNodeId = null;
    });
  }

  Widget _buildHeader() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Interactive Galaxy',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white24, size: 20),
            onPressed: () {
               setState(() {
                  _initialized = false;
                  _nodes = []; // This will trigger re-fetch from provider state
               });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayInstructions() {
    return const Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          'Grab stars to move them • Connections act as springs\nStars bounce off walls',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 10, height: 1.5, letterSpacing: 0.5),
        ),
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
  final String? draggedId;

  ConstellationPhysicsPainter({
    required this.nodes,
    required this.edges,
    this.selectedId,
    this.draggedId,
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
      final from = nodes.where((n) => n.id == edge.fromId).firstOrNull;
      final to = nodes.where((n) => n.id == edge.toId).firstOrNull;
      if (from == null || to == null) continue;

      final isHighlighted = (selectedId == from.id || selectedId == to.id || draggedId == from.id || draggedId == to.id);
      
      if (isHighlighted) {
         canvas.drawLine(from.position, to.position, highlightLinePaint);
      } else {
         canvas.drawLine(from.position, to.position, linePaint);
      }
    }

    // 4. Nodes
    final now = DateTime.now();
    for (final node in nodes) {
      final isSelected = node.id == selectedId;
      final isDragged = node.id == draggedId;
      final color = _getNodeColor(node.type);
      
      final ageHours = now.difference(node.date).inHours;
      final ageFactor = (1.0 - (ageHours / 168.0)).clamp(0.4, 1.0);
      
      // Glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: (isDragged ? 0.4 : 0.2) * ageFactor)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (isDragged || isSelected) ? 15 : 8);
      canvas.drawCircle(node.position, 15 + (isDragged ? 10 : 0), glowPaint);

      // Core
      final starPaint = Paint()..color = isSelected || isDragged ? Colors.white : color;
      canvas.drawCircle(node.position, 4 * ageFactor + (isDragged ? 3 : 0), starPaint);
      
      // Ring
      final ringPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawCircle(node.position, 10 * ageFactor, ringPaint);
    }
  }

  Color _getNodeColor(ConstellationNodeType type) {
    switch (type) {
      case ConstellationNodeType.decision: return const Color(0xFF38BDF8);
      case ConstellationNodeType.retro: return const Color(0xFFFB7185);
      case ConstellationNodeType.declaration: return const Color(0xFFFBBF24);
      case ConstellationNodeType.check: return const Color(0xFF34D399);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
