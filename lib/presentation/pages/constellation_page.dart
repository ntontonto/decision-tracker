import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoshi_log/domain/models/constellation_models.dart';
import 'package:hoshi_log/data/local/database.dart';
import 'package:hoshi_log/domain/providers/constellation_providers.dart';
import 'package:hoshi_log/domain/providers/app_providers.dart';
import '../widgets/decision_detail_sheet.dart';
import '../widgets/constellation_node_card.dart';
import '../widgets/log_wizard_sheet.dart';
import '../theme/app_design.dart';
import 'dart:ui';

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
  AnimationController? _cameraAnimationController;
  int _revealedCount = 0;
  bool _showGalaxy = false;
  
  // Navigation State
  String? _selectedNodeId;
  String? _focusedChainId;
  List<ConstellationNode> _swipeNodes = [];
  late PageController _pageController;
  bool _isAnimatingCamera = false;
  bool _isCardVisible = false;
  bool _isCardExpanded = false;
  
  // Animation state for newly reviewed stars
  final Map<String, double> _glowProgress = {};
  
  // Entrance & Exit Animations
  final Map<String, double> _entranceProgress = {};
  final Map<String, double> _exitProgress = {};
  final List<ConstellationNode> _zombieNodes = [];
  final List<ConstellationEdge> _zombieEdges = [];
  
  // Sorting & Direction State
  ConstellationSortMode _sortMode = ConstellationSortMode.none;
  List<_ChainMeta> _chainMetasRaw = []; // Helper for indices
  List<String> _sortedChainIds = [];
  ConstellationSortMode? _lastSortMode;
  bool _isSortDescending = true;
  
  // Chain Meta Info for sorting
  Map<String, _ChainMeta> _chainMetas = {};
  final Set<String> _kickedNodeIds = {};
  
  // Simulation State
  List<ConstellationNode> _nodes = [];
  List<ConstellationEdge> _edges = [];
  Size _worldSize = const Size(2000, 2000);
  bool _initialized = false;
  int _settleCooldown = 0;

  Offset _lastPointerDownPos = Offset.zero;

  // Double-tap-drag zoom state
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;
  bool _isDoubleTapDragging = false;
  double _initialScaleOnDoubleTap = 1.0;
  Offset _doubleTapReferenceScenePos = Offset.zero;
  Offset _doubleTapStartViewportPos = Offset.zero;
  bool _isIVEnabled = true;

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
      
      final t = Curves.easeInOutCubic.transform(_revelationController.value);
      
      // Update revealed count
      final count = (Curves.easeIn.transform(_revelationController.value) * _nodes.length).floor();
      if (count != _revealedCount) {
        setState(() => _revealedCount = count);
      }

      // Update camera zoom-out if not manually interrupted
      if (!_isAnimatingCamera && !_isDoubleTapDragging && _initialized) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        // Final State (Galaxy View)
        final finalScale = 0.4;
        final finalX = (screenWidth - _worldSize.width * finalScale) / 2;
        final finalY = (screenHeight - _worldSize.height * finalScale) / 2;
        
        // Initial State (Zoomed on first star)
        final startScale = 1.5;
        final startX = screenWidth / 2 - _nodes[0].position.dx * startScale;
        final startY = screenHeight / 2 - _nodes[0].position.dy * startScale;
        
        // Interpolate
        final currentScale = startScale + (finalScale - startScale) * t;
        final currentX = startX + (finalX - startX) * t;
        final currentY = startY + (finalY - startY) * t;
        
        _transformationController.value = Matrix4.identity()
          ..setTranslationRaw(currentX, currentY, 0)
          ..scale(currentScale, currentScale, 1.0);
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _transformationController.dispose();
    _pageController.dispose();
    _revelationController.dispose();
    _cameraAnimationController?.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_nodes.isEmpty) return;

    if (_settleCooldown > 0) {
      _settleCooldown--;
    }

    if (mounted) {
      setState(() {
        _applyPhysics();
        _updateAnimations();
      });
    }
  }

  void _updateAnimations() {
    final toRemoveGlow = <String>[];
    _glowProgress.forEach((id, progress) {
      final newProgress = progress - 0.02; // Decrease over ~50 ticks (1 sec at 60fps)
      if (newProgress <= 0) {
        toRemoveGlow.add(id);
      } else {
        _glowProgress[id] = newProgress;
      }
    });
    for (final id in toRemoveGlow) {
      _glowProgress.remove(id);
    }

    // Update entrance progress
    final toRemoveEntrance = <String>[];
    _entranceProgress.forEach((id, progress) {
      final newProgress = (progress + 0.03).clamp(0.0, 1.0);
      if (newProgress >= 1.0) {
        toRemoveEntrance.add(id);
      } else {
        _entranceProgress[id] = newProgress;
      }
    });
    for (final id in toRemoveEntrance) {
      _entranceProgress.remove(id);
    }

    // Update exit progress
    final toRemoveExit = <String>[];
    _exitProgress.forEach((id, progress) {
      final newProgress = (progress - 0.03).clamp(0.0, 1.0);
      if (newProgress <= 0) {
        toRemoveExit.add(id);
      } else {
        _exitProgress[id] = newProgress;
      }
    });
    
    // Cleanup zombie nodes/edges whose animation finished
    for (final id in toRemoveExit) {
      _exitProgress.remove(id);
      _zombieNodes.removeWhere((n) => n.id == id);
      _zombieEdges.removeWhere((e) => '${e.fromId}-${e.toId}' == id);
    }
  }

  void _applyPhysics() {
    const double friction = 0.98;
    const double stabilizationFriction = 0.88;
    const double springK = 0.03; // Pull strength
    const double restLength = 80.0; // Desired distance
    const double repulsionK = 50.0; // Avoid overlapping

    final currentBaseFriction = _settleCooldown > 0 ? stabilizationFriction : friction;

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
      var node = _nodes[i];
      
      // Dynamic Friction: Significant friction when sorting or stabilizing to settle faster
      var currentFriction = (_sortMode != ConstellationSortMode.none) ? 0.75 : currentBaseFriction;
      var vel = node.velocity * currentFriction;
      
      // 4. Target Attraction (Sorting)
      if (_sortMode != ConstellationSortMode.none) {
        final meta = _chainMetas[node.chainId];
        if (meta != null && meta.focusNodeId == node.id && meta.targetY != null) {
          final dy = meta.targetY! - node.position.dy;
          final dx = (meta.targetX ?? node.position.dx) - node.position.dx;
          
          // Lower spring force for slower, graceful movement
          final dist = math.sqrt(dx * dx + dy * dy);
          final strength = dist > 10 ? 0.08 : 0.15; 
          
          // Stronger damping to eliminate 'boing' (overshoot)
          vel = vel * 0.82;
          
          // Latter-half Kick: Apply a subtle randomized impulse as nodes approach targets
          if (dist < 300 && dist > 50 && !_kickedNodeIds.contains(node.id)) {
            final randomGen = math.Random();
            if (randomGen.nextDouble() > 0.4) { // 60% chance
              final nodeRandom = math.Random(node.id.hashCode + _sortMode.index);
              final kickX = (nodeRandom.nextDouble() - 0.5) * 40; 
              final kickY = (nodeRandom.nextDouble() - 0.5) * 20;
              vel = vel + Offset(kickX, kickY);
            }
            _kickedNodeIds.add(node.id);
          }

          vel = Offset(vel.dx + dx * strength, vel.dy + dy * strength);
        } else if (node.generation > 0) {
          // 5. Lateral Scatter for Satellites
          // Push satellites horizontally away from the center to prevent vertical collapse
          final centerX = _worldSize.width / 2;
          final dxFromCenter = node.position.dx - centerX;
          
          if (dxFromCenter.abs() < 40) {
             // Slight push based on ID to make it deterministic
             final pushDir = (node.id.hashCode % 2 == 0) ? 1.0 : -1.0;
             vel = Offset(vel.dx + pushDir * 0.5, vel.dy);
          }
        }
      }

      var pos = node.position + vel;

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
    if (_nodes.isEmpty) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Start zoomed in on the first star
    const startScale = 1.5;
    final xTranslation = screenWidth / 2 - _nodes[0].position.dx * startScale;
    final yTranslation = screenHeight / 2 - _nodes[0].position.dy * startScale;

    _transformationController.value = Matrix4.identity()
      ..setTranslationRaw(xTranslation, yTranslation, 0)
      ..scale(startScale, startScale, 1.0);

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
                _calculateChainMetas();
                setState(() => _showGalaxy = true);
                _revelationController.forward(from: 0.0);
              }
            });
          } else if (_nodes.isNotEmpty && graph.nodes.isNotEmpty) {
            // Reactive Sync: Update existing nodes without re-shuffling layout
            bool changed = false;
            
            // 1. Check for NEW nodes
            for (final newNode in graph.nodes) {
              final existsInNodes = _nodes.any((n) => n.id == newNode.id);
              final existsInZombies = _zombieNodes.any((n) => n.id == newNode.id);
              
              if (!existsInNodes && !existsInZombies) {
                // Truly new node!
                _nodes.add(newNode);
                _entranceProgress[newNode.id] = 0.0;
                _settleCooldown = 120; // Stabilize for 2 seconds
                
                // If initial sequence is done, immediately reveal the new star
                if (!_revelationController.isAnimating) {
                  _revealedCount = _nodes.length;
                }
                
                changed = true;
              } else if (existsInNodes) {
                // Update existing node properties
                final idx = _nodes.indexWhere((n) => n.id == newNode.id);
                final oldNode = _nodes[idx];
                
                // Detect any visual or data changes
                bool isDataChanged = oldNode.label != newNode.label || 
                                    oldNode.originalData != newNode.originalData;
                bool isStatusChanged = oldNode.isReviewed != newNode.isReviewed || 
                                      oldNode.score != newNode.score;

                if (isDataChanged || isStatusChanged) {
                  _nodes[idx] = oldNode.copy(
                    isReviewed: newNode.isReviewed,
                    score: newNode.score,
                    label: newNode.label,
                    originalData: newNode.originalData,
                  );
                  
                  // Trigger glow if newly reviewed
                  if (!oldNode.isReviewed && newNode.isReviewed) {
                    _glowProgress[newNode.id] = 1.0;
                  }
                  changed = true;
                }
              }
            }

            // 2. Check for REMOVED nodes
            final nodesToRemove = <ConstellationNode>[];
            for (final oldNode in _nodes) {
              if (!graph.nodes.any((n) => n.id == oldNode.id)) {
                nodesToRemove.add(oldNode);
              }
            }
            if (nodesToRemove.isNotEmpty) {
              for (final node in nodesToRemove) {
                _nodes.remove(node);
                _zombieNodes.add(node);
                _exitProgress[node.id] = 1.0;
                _entranceProgress.remove(node.id);
              }
              changed = true;
            }

            // 3. Sync Edges
            // Check for NEW edges
            for (final newEdge in graph.edges) {
              final edgeKey = '${newEdge.fromId}-${newEdge.toId}';
              final existsInEdges = _edges.any((e) => e.fromId == newEdge.fromId && e.toId == newEdge.toId);
              final existsInZombies = _zombieEdges.any((e) => '${e.fromId}-${e.toId}' == edgeKey);
              
              if (!existsInEdges && !existsInZombies) {
                _edges.add(newEdge);
                _entranceProgress[edgeKey] = 0.0;
                changed = true;
              }
            }
            // Check for REMOVED edges
            final edgesToRemove = <ConstellationEdge>[];
            for (final oldEdge in _edges) {
              if (!graph.edges.any((e) => e.fromId == oldEdge.fromId && e.toId == oldEdge.toId)) {
                edgesToRemove.add(oldEdge);
              }
            }
            if (edgesToRemove.isNotEmpty) {
              for (final edge in edgesToRemove) {
                _edges.remove(edge);
                _zombieEdges.add(edge);
                final edgeKey = '${edge.fromId}-${edge.toId}';
                _exitProgress[edgeKey] = 1.0;
                _entranceProgress.remove(edgeKey);
              }
              changed = true;
            }

            if (changed) {
              _recalculateSwipeNodes();
              // refreshing swipe nodes might require resetting the page controller if focus is lost or changed
              // for now we just trigger a repaint
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() {});
              });
            }
          }
          
          final filteredNodes = _nodes;
          
          WidgetsBinding.instance.addPostFrameCallback((_) => _initializeViewport(_worldSize));

          return Stack(
            children: [
              _buildSpaceBackground(),
              _buildInteractionLayer(filteredNodes),
              // Passive Interaction Layer: Handle taps without blocking IV scrolls
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) {
                    _lastPointerDownPos = event.position;
                    
                    final now = DateTime.now();
                    if (_lastTapTime != null && _lastTapPosition != null) {
                      final timeDiff = now.difference(_lastTapTime!);
                      final distDiff = (event.position - _lastTapPosition!).distance;
                      
                      // Check for double tap (within 300ms and 40 pixels)
                      if (timeDiff.inMilliseconds < 300 && distDiff < 40) {
                        setState(() {
                          _isDoubleTapDragging = true;
                          _isIVEnabled = false;
                          _initialScaleOnDoubleTap = _transformationController.value.getMaxScaleOnAxis();
                          _doubleTapReferenceScenePos = _transformationController.toScene(event.localPosition);
                          _doubleTapStartViewportPos = event.localPosition;
                        });
                      }
                    }
                    _lastTapTime = now;
                    _lastTapPosition = event.position;
                  },
                  onPointerMove: (event) {
                    if (_isDoubleTapDragging) {
                      final dy = event.position.dy - _lastTapPosition!.dy;
                      // Google Maps behavior: swipe down to zoom in, swipe up to zoom out
                      // Sensitivity factor - adjust as needed
                      final zoomSensitivity = 0.005;
                      final scaleFactor = math.exp(dy * zoomSensitivity);
                      final newScale = (_initialScaleOnDoubleTap * scaleFactor).clamp(0.1, 2.5);
                      
                      // Update matrix centering on the reference scene position
                      final scenePos = _doubleTapReferenceScenePos;
                      final viewportPos = _doubleTapStartViewportPos;
                      
                      // Calculate the new translation to keep the scene point under the pointer
                      setState(() {
                        _transformationController.value = Matrix4.identity()
                          ..translate(viewportPos.dx - scenePos.dx * newScale, viewportPos.dy - scenePos.dy * newScale)
                          ..scale(newScale);
                      });
                    }
                  },
                  onPointerUp: (event) {
                    if (_isDoubleTapDragging) {
                      setState(() {
                        _isDoubleTapDragging = false;
                        _isIVEnabled = true;
                      });
                    } else {
                      final distance = (event.position - _lastPointerDownPos).distance;
                      if (distance < 10) { // Genuine tap, not a scroll
                        final viewportPos = event.localPosition;
                        final scenePos = _transformationController.toScene(viewportPos);
                        _handleTapAt(scenePos, viewportPos);
                      }
                    }
                  },
                ),
              ),
              _buildHeader(),
              _buildDetailOverlay(),
              _buildVerticalNavigationButtons(),
              if (!_showGalaxy || _revelationController.isAnimating || filteredNodes.isEmpty) 
                _buildOverlayInstructions(filteredNodes.isEmpty),
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

  Widget _buildInteractionLayer(List<ConstellationNode> filteredNodes) {
    return AnimatedOpacity(
      opacity: _showGalaxy ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeIn,
      child: InteractiveViewer(
        transformationController: _transformationController,
        boundaryMargin: const EdgeInsets.all(2000),
        minScale: 0.1,
        maxScale: 2.5,
        panEnabled: _isIVEnabled,
        scaleEnabled: _isIVEnabled,
        child: CustomPaint(
          size: _worldSize,
          painter: ConstellationPhysicsPainter(
            nodes: filteredNodes,
            edges: _edges,
            zombieNodes: _zombieNodes,
            zombieEdges: _zombieEdges,
            selectedId: _selectedNodeId,
            revealedCount: _revealedCount,
            glowProgress: Map.from(_glowProgress),
            entranceProgress: Map.from(_entranceProgress),
            exitProgress: Map.from(_exitProgress),
            sortMode: _sortMode,
            focusNodeIds: _chainMetas.values.map((m) => m.focusNodeId).toSet(),
            minTargetY: (_sortMode == ConstellationSortMode.none || _chainMetas.isEmpty) ? null : _chainMetas.values.map((m) => m.targetY!).reduce(math.min),
            maxTargetY: (_sortMode == ConstellationSortMode.none || _chainMetas.isEmpty) ? null : _chainMetas.values.map((m) => m.targetY!).reduce(math.max),
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

  void _focusNode(ConstellationNode node, {Offset? targetPosOverride}) {
    setState(() {
      _selectedNodeId = node.id;
      if (_focusedChainId != node.chainId) {
        _focusedChainId = node.chainId;
      }
      _recalculateSwipeNodes();
      _isCardExpanded = false;
      _isCardVisible = true;
    });

    // Sync PageView
    final pageIndex = _swipeNodes.indexWhere((n) => n.id == node.id);
    if (pageIndex != -1) {
      if (_pageController.hasClients) {
        if (_pageController.page?.round() != pageIndex) {
          _pageController.animateToPage(
            pageIndex, 
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeInOut,
          );
        }
      } else {
        // If not yet visible/built, we need to create a new controller with the correct initialPage
        _pageController.dispose();
        _pageController = PageController(initialPage: pageIndex);
      }
    }

    _animateCameraToNode(node, targetPosOverride: targetPosOverride);
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
          _swipeNodes = [];
        });
      }
    });
  }

  void _recalculateSwipeNodes() {
    if (_nodes.isEmpty) {
      _swipeNodes = [];
      return;
    }

    // 1. Group nodes by chainId
    final Map<String, List<ConstellationNode>> chains = {};
    for (final node in _nodes) {
      chains.putIfAbsent(node.chainId, () => []).add(node);
    }

    // 2. Sort each chain by generation
    for (final chain in chains.values) {
      chain.sort((a, b) => a.generation.compareTo(b.generation));
    }

    // 3. Get all chains and sort them by the date of their root node (generation 0)
    final sortedChains = chains.values.toList()..sort((a, b) {
      final rootA = a.firstWhere((n) => n.generation == 0, orElse: () => a.first);
      final rootB = b.firstWhere((n) => n.generation == 0, orElse: () => b.first);
      return rootA.date.compareTo(rootB.date);
    });

    // 4. Flatten into a single list
    _swipeNodes = sortedChains.expand((chain) => chain).toList();
  }

  void _animateCameraToNode(ConstellationNode node, {Offset? targetPosOverride}) {
    _cameraAnimationController?.stop();
    _cameraAnimationController?.dispose();

    _isAnimatingCamera = true;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const targetScale = 0.8;

    final basePos = targetPosOverride ?? node.position;
    final targetX = screenWidth / 2 - basePos.dx * targetScale;
    final targetY = screenHeight / 2 - basePos.dy * targetScale;

    final endMatrix = Matrix4.identity()
      ..setTranslationRaw(targetX, targetY, 0)
      ..scale(targetScale, targetScale, 1.0);

    final startMatrix = _transformationController.value;
    _cameraAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final matrixTween = Matrix4Tween(begin: startMatrix, end: endMatrix);
    _cameraAnimationController!.addListener(() {
      _transformationController.value = matrixTween.evaluate(CurvedAnimation(
        parent: _cameraAnimationController!,
        curve: Curves.fastOutSlowIn,
      ));
    });
    
    _cameraAnimationController!.forward().then((_) {
      if (mounted) {
        setState(() => _isAnimatingCamera = false);
      }
    });
  }

  ConstellationNode? _findNodeAt(Offset scenePos) {
    // Check revealed nodes only
    for (int i = 0; i < _revealedCount && i < _nodes.length; i++) {
      final node = _nodes[i];
      final distance = (node.position - scenePos).distance;
      if (distance < 35) { // Reduced hitbox radius to match satellite orbit
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
          // Glass Sort Menu Button
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: PopupMenuButton<ConstellationSortMode>(
                    offset: const Offset(0, 48),
                    elevation: 0,
                    color: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sortMode == ConstellationSortMode.none 
                                ? Icons.sort 
                                : (_isSortDescending ? Icons.expand_more : Icons.expand_less),
                            color: Colors.white70,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    onSelected: (mode) {
                      setState(() {
                        if (_sortMode == mode) {
                          _isSortDescending = !_isSortDescending;
                        } else {
                          _sortMode = mode;
                        }
                      });
                      _calculateChainMetas();
                      _focusTopStarAfterSort();
                    },
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem<ConstellationSortMode>(
                          enabled: false,
                          height: 0,
                          child: Container(),
                        ),
                        ...ConstellationSortMode.values
                          .where((m) => m != ConstellationSortMode.none)
                          .map((mode) {
                          final isSelected = _sortMode == mode;
                          return PopupMenuItem<ConstellationSortMode>(
                            value: mode,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected 
                                        ? Colors.white.withValues(alpha: 0.3)
                                        : Colors.white.withValues(alpha: 0.1),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          mode.label,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.white70,
                                            fontSize: 14,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          _isSortDescending ? Icons.expand_more : Icons.expand_less,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ];
                    },
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildOverlayInstructions(bool isEmptyState) {
    if (isEmptyState) {
      return Positioned.fill(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white24, size: 48),
              const SizedBox(height: 24),
              const Text(
                'あなたの夜空に、最初の光を灯しましょう',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => const LogWizardSheet(),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '今日のできごとを記録する',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
    final screenHeight = MediaQuery.of(context).size.height;
    final collapsedHeight = 220.0;
    final expandedHeight = screenHeight * 0.7;
    final currentHeight = _isCardExpanded ? expandedHeight : collapsedHeight;

    final isShowing = _isCardVisible && _swipeNodes.isNotEmpty;

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
        child: IgnorePointer(
          ignoring: !isShowing,
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
              child: _swipeNodes.isEmpty 
                ? const SizedBox.shrink()
                : PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(), // Always allow horizontal swiping
                    itemCount: _swipeNodes.length,
                    onPageChanged: (index) {
                      if (_pageController.hasClients && _pageController.page?.round() == index) {
                        if (!_isAnimatingCamera) {
                          _animateCameraToNode(_swipeNodes[index]);
                          setState(() {
                            _selectedNodeId = _swipeNodes[index].id;
                            _focusedChainId = _swipeNodes[index].chainId;
                          });
                        }
                      }
                    },
                    itemBuilder: (context, index) {
                      final node = _swipeNodes[index];
                      return ConstellationNodeCard(
                        node: node,
                        isExpanded: _isCardExpanded,
                        onDelete: () async {
                          // 1. Clear focus immediately to close the card
                          _clearFocus();
                          
                          // 2. Perform deletion
                          final repo = ref.read(decisionRepositoryProvider);
                          if (node.type == ConstellationNodeType.decision) {
                            final decision = node.originalData as Decision;
                            await repo.deleteDecision(decision.id);
                          } else {
                            final decl = node.originalData as Declaration;
                            await repo.deleteDeclaration(decl.id);
                          }
                          
                          // 3. Invalidate providers to refresh the graph
                          ref.invalidate(allDecisionsProvider);
                          ref.invalidate(constellationProvider);
                          ref.invalidate(pendingDecisionsProvider);
                          ref.invalidate(pendingDeclarationsProvider);
                        },
                      );
                    },
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalNavigationButtons() {
    final screenHeight = MediaQuery.of(context).size.height;
    final collapsedHeight = 220.0;
    final expandedHeight = screenHeight * 0.7;
    final currentHeight = _isCardExpanded ? expandedHeight : collapsedHeight;
    final isShowingCard = _isCardVisible;
    final isEmptyState = _nodes.isEmpty;

    // Determine if we can go up or down
    final currentIndex = _sortedChainIds.indexOf(_focusedChainId ?? '');
    final canGoUp = currentIndex > 0;
    final canGoDown = currentIndex != -1 && currentIndex < _sortedChainIds.length - 1;
    final hasSortArrows = _sortMode != ConstellationSortMode.none && _swipeNodes.isNotEmpty;

    return AnimatedPositioned(
      key: const ValueKey('vert_nav_buttons'),
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      bottom: isShowingCard ? currentHeight + 16 : 32 + MediaQuery.of(context).padding.bottom,
      right: 20,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: (_showGalaxy || isEmptyState) ? 1.0 : 0.0,
        child: Column(
          children: [
            _buildGlassNavButton(
              icon: Icons.auto_awesome,
              onPressed: () => Navigator.pop(context),
              enabled: true,
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1.0, // Top-weighted expansion
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: hasSortArrows
                  ? Padding(
                      key: const ValueKey('sorting_arrows'),
                      padding: const EdgeInsets.only(top: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGlassNavButton(
                            icon: Icons.keyboard_arrow_up,
                            onPressed: canGoUp ? () => _navigateVertical(false) : null,
                            enabled: canGoUp,
                          ),
                          const SizedBox(height: 12),
                          _buildGlassNavButton(
                            icon: Icons.keyboard_arrow_down,
                            onPressed: canGoDown ? () => _navigateVertical(true) : null,
                            enabled: canGoDown,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no_arrows')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
    bool enabled = true,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: enabled ? 0.15 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: enabled ? 0.2 : 0.05),
              width: 0.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Icon(
                icon,
                color: enabled ? Colors.white : Colors.white24,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }


  void _calculateChainMetas() {
    if (_sortMode == ConstellationSortMode.none) {
      _lastSortMode = _sortMode;
      setState(() => _chainMetas = {});
      return;
    }

    // Reset kick tracking when switching sort modes
    if (_lastSortMode != _sortMode) {
      _kickedNodeIds.clear();
      _lastSortMode = _sortMode;
    }

    final Map<String, List<ConstellationNode>> chains = {};
    for (final node in _nodes) {
      chains.putIfAbsent(node.chainId, () => []).add(node);
    }

    final List<_ChainMeta> sortedMetas = [];
    chains.forEach((chainId, nodesInChain) {
      final rootNode = nodesInChain.firstWhere((n) => n.generation == 0, orElse: () => nodesInChain.first);
      
      // Find latest action date and unreviewed status
      DateTime latestDate = rootNode.date;
      ConstellationNode latestNode = rootNode;
      ConstellationNode? firstUnreviewedNode;
      DateTime? latestScheduledReflectionDate;
      ConstellationNode? latestScheduledReflectionNode;

      // Ensure nodes are sorted by generation to find "first" unreviewed correctly
      nodesInChain.sort((a, b) => a.generation.compareTo(b.generation));

      for (final node in nodesInChain) {
        if (node.date.isAfter(latestDate)) {
          latestDate = node.date;
          latestNode = node;
        }
        if (firstUnreviewedNode == null && !node.isReviewed) {
          firstUnreviewedNode = node;
        }
        if (node.scheduledReflectionDate != null) {
          if (latestScheduledReflectionDate == null || node.scheduledReflectionDate!.isAfter(latestScheduledReflectionDate)) {
            latestScheduledReflectionDate = node.scheduledReflectionDate;
            latestScheduledReflectionNode = node;
          }
        }
      }

      final hasUnreviewed = firstUnreviewedNode != null;

      // Determine Focus Node ID based on Sort Mode
      String focusNodeId = rootNode.id;
      if (_sortMode == ConstellationSortMode.unreviewedFirst && hasUnreviewed) {
        focusNodeId = firstUnreviewedNode.id;
      } else if (_sortMode == ConstellationSortMode.latestActionDate) {
        focusNodeId = latestNode.id;
      } else if (_sortMode == ConstellationSortMode.reflectionDate && latestScheduledReflectionNode != null) {
        focusNodeId = latestScheduledReflectionNode.id;
      }

      sortedMetas.add(_ChainMeta(
        chainId: chainId,
        rootDate: rootNode.date,
        latestDate: latestDate,
        hasUnreviewed: hasUnreviewed,
        focusNodeId: focusNodeId,
        latestScheduledReflectionDate: latestScheduledReflectionDate,
      ));
    });

    // Apply Sorting to Metas to determine Target Y
    if (_sortMode == ConstellationSortMode.unreviewedFirst) {
      sortedMetas.sort((a, b) {
        if (a.hasUnreviewed != b.hasUnreviewed) {
          return _isSortDescending 
            ? (a.hasUnreviewed ? -1 : 1)
            : (a.hasUnreviewed ? 1 : -1);
        }
        return _isSortDescending 
          ? b.rootDate.compareTo(a.rootDate)
          : a.rootDate.compareTo(b.rootDate);
      });
    } else if (_sortMode == ConstellationSortMode.decisionDate) {
      sortedMetas.sort((a, b) => _isSortDescending 
        ? b.rootDate.compareTo(a.rootDate)
        : a.rootDate.compareTo(b.rootDate));
    } else if (_sortMode == ConstellationSortMode.latestActionDate) {
      sortedMetas.sort((a, b) => _isSortDescending 
        ? b.latestDate.compareTo(a.latestDate)
        : a.latestDate.compareTo(b.latestDate));
    } else if (_sortMode == ConstellationSortMode.reflectionDate) {
      sortedMetas.sort((a, b) {
        final dateA = a.latestScheduledReflectionDate;
        final dateB = b.latestScheduledReflectionDate;
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return _isSortDescending 
          ? dateB.compareTo(dateA)
          : dateA.compareTo(dateB);
      });
    }

    // List Visibility: tighter spacing (list view style)
    // final worldHeight = _worldSize.height; // Remnant of unused code
    final worldWidth = _worldSize.width;
    final paddingY = 600.0;
    final spacing = 140.0; // Slightly more vertical gap for focus nodes
    
    for (int i = 0; i < sortedMetas.length; i++) {
        sortedMetas[i] = sortedMetas[i].copyWith(
          targetY: paddingY + (i * spacing),
          targetX: worldWidth / 2,
        );
    }

    setState(() {
      _chainMetas = {for (var m in sortedMetas) m.chainId: m};
      _sortedChainIds = sortedMetas.map((m) => m.chainId).toList();
      _chainMetasRaw = sortedMetas;
    });
  }

  void _navigateVertical(bool forward) {
    if (_sortedChainIds.isEmpty || _selectedNodeId == null || _focusedChainId == null) return;

    final currentIndex = _sortedChainIds.indexOf(_focusedChainId!);
    if (currentIndex == -1) return;

    final targetIndex = forward ? currentIndex + 1 : currentIndex - 1;
    if (targetIndex < 0 || targetIndex >= _sortedChainIds.length) return;

    final targetChainId = _sortedChainIds[targetIndex];
    final targetMeta = _chainMetas[targetChainId];
    if (targetMeta == null) return;

    // Find equivalent node in the target chain
    // Equivalent is defined as same generation offset relative to focusNode
    final currentFocusNodeId = _chainMetas[_focusedChainId]?.focusNodeId;
    final currentNode = _nodes.firstWhere((n) => n.id == _selectedNodeId);
    final currentFocusNode = _nodes.firstWhere((n) => n.id == currentFocusNodeId);
    
    final genDiff = currentNode.generation - currentFocusNode.generation;

    final targetChainNodes = _nodes.where((n) => n.chainId == targetChainId).toList()
      ..sort((a, b) => a.generation.compareTo(b.generation));
    
    final targetFocusNode = targetChainNodes.firstWhere((n) => n.id == targetMeta.focusNodeId);
    final targetGeneration = targetFocusNode.generation + genDiff;

    // Try to find exact generation, or closest
    ConstellationNode targetNode = targetFocusNode;
    int minDiff = 100;
    for (final node in targetChainNodes) {
      final diff = (node.generation - targetGeneration).abs();
      if (diff < minDiff) {
        minDiff = diff;
        targetNode = node;
      }
    }

    Offset? targetOverride;
    if (targetMeta.targetX != null && targetMeta.targetY != null) {
      // We need to adjust targetY based on the node's generation relative to the focus node
      // The spacing between generations is roughly 200 in chain-link logic
      // But in list view, they are all squashed. 
      // Actually, targetY/targetX in ChainMeta is for the FOCUS star.
      targetOverride = Offset(targetMeta.targetX!, targetMeta.targetY!);
    }

    _focusNode(targetNode, targetPosOverride: targetOverride);
  }

  void _focusTopStarAfterSort() {
    if (_chainMetas.isEmpty) return;
    
    // The chain metas are already sorted by targetY in _calculateChainMetas
    // We can just find the one with the minimum targetY
    _ChainMeta? topMeta;
    double minY = double.infinity;
    
    _chainMetas.forEach((id, meta) {
      if (meta.targetY != null && meta.targetY! < minY) {
        minY = meta.targetY!;
        topMeta = meta;
      }
    });

    if (topMeta != null) {
      final topNode = _nodes.firstWhere((n) => n.id == topMeta!.focusNodeId);
      // Pass the target destination to ensure camera moves correctly even before star settles
      Offset? targetOverride;
      if (topMeta!.targetX != null && topMeta!.targetY != null) {
        targetOverride = Offset(topMeta!.targetX!, topMeta!.targetY!);
      }
      
      // Force trigger focus animation even if already selected
      _focusNode(topNode, targetPosOverride: targetOverride);
    }
  }
}

class _ChainMeta {
  final String chainId;
  final String focusNodeId;
  final DateTime rootDate;
  final DateTime latestDate;
  final bool hasUnreviewed;
  final DateTime? latestScheduledReflectionDate;
  final double? targetY;
  final double? targetX;

  _ChainMeta({
    required this.chainId,
    required this.focusNodeId,
    required this.rootDate,
    required this.latestDate,
    required this.hasUnreviewed,
    this.latestScheduledReflectionDate,
    this.targetY,
    this.targetX,
  });

  _ChainMeta copyWith({double? targetY, double? targetX}) {
    return _ChainMeta(
      chainId: chainId,
      focusNodeId: focusNodeId,
      rootDate: rootDate,
      latestDate: latestDate,
      hasUnreviewed: hasUnreviewed,
      latestScheduledReflectionDate: latestScheduledReflectionDate,
      targetY: targetY ?? this.targetY,
      targetX: targetX ?? this.targetX,
    );
  }
}

class ConstellationPhysicsPainter extends CustomPainter {
  final List<ConstellationNode> nodes;
  final List<ConstellationEdge> edges;
  final List<ConstellationNode> zombieNodes;
  final List<ConstellationEdge> zombieEdges;
  final String? selectedId;
  final int revealedCount;
  final Map<String, double> glowProgress;
  final Map<String, double> entranceProgress;
  final Map<String, double> exitProgress;
  final ConstellationSortMode sortMode;
  final Set<String> focusNodeIds;
  final double? minTargetY;
  final double? maxTargetY;

  ConstellationPhysicsPainter({
    required this.nodes,
    required this.edges,
    required this.zombieNodes,
    required this.zombieEdges,
    this.selectedId,
    required this.revealedCount,
    required this.glowProgress,
    required this.entranceProgress,
    required this.exitProgress,
    required this.sortMode,
    required this.focusNodeIds,
    this.minTargetY,
    this.maxTargetY,
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

    // 2. Guide Line (Auxiliary Line for sorting) - Drawn in Background Layer
    if (minTargetY != null && maxTargetY != null) {
      final centerX = size.width / 2;
      final startY = minTargetY! - 150;
      final endY = maxTargetY! + 150;

      if (endY > startY) {
        // Subtle Cyan Glow
        final glowPaint = Paint()
          ..color = Colors.cyan.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        
        final guidePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
          
        canvas.drawLine(Offset(centerX, startY), Offset(centerX, endY), glowPaint);

        // Dashed Line
        const dashHeight = 15.0;
        const dashSpace = 10.0;
        double currentY = startY;
        while (currentY < endY) {
          canvas.drawLine(
            Offset(centerX, currentY),
            Offset(centerX, math.min(currentY + dashHeight, endY)),
            guidePaint,
          );
          currentY += dashHeight + dashSpace;
        }
      }
    }


    // 2. Edges
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final highlightLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 3. Edges
    final allEdges = [...edges, ...zombieEdges];
    final allNodes = [...nodes, ...zombieNodes];

    for (final edge in allEdges) {
      final fromIdx = allNodes.indexWhere((n) => n.id == edge.fromId);
      final toIdx = allNodes.indexWhere((n) => n.id == edge.toId);
      if (fromIdx == -1 || toIdx == -1) continue;
      
      final from = allNodes[fromIdx];
      final to = allNodes[toIdx];

      // Revealed check for live nodes
      final bool fromIsLive = nodes.any((n) => n.id == from.id);
      final bool toIsLive = nodes.any((n) => n.id == to.id);
      
      if (fromIsLive && nodes.indexOf(from) >= revealedCount) continue;
      if (toIsLive && nodes.indexOf(to) >= revealedCount) continue;

      final isHighlighted = (selectedId == from.id || selectedId == to.id);
      final edgeKey = '${edge.fromId}-${edge.toId}';
      
      double edgeOpacity = 1.0;
      if (entranceProgress.containsKey(edgeKey)) {
        edgeOpacity = entranceProgress[edgeKey]!;
      } else if (exitProgress.containsKey(edgeKey)) {
        edgeOpacity = exitProgress[edgeKey]!;
      }

      final Paint currentLinePaint = (isHighlighted ? highlightLinePaint : linePaint);
      final Color originalColor = currentLinePaint.color;
      currentLinePaint.color = originalColor.withValues(alpha: originalColor.a * edgeOpacity);
      
      canvas.drawLine(from.position, to.position, currentLinePaint);
      
      // Restore color for next iteration
      currentLinePaint.color = originalColor;
    }

    // 4. Nodes
    final now = DateTime.now();

    final datePainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < allNodes.length; i++) {
      final node = allNodes[i];
      final bool isZombie = zombieNodes.any((n) => n.id == node.id);
      
      if (!isZombie && nodes.indexOf(node) >= revealedCount) continue;

      final isSelected = node.id == selectedId;
      final bool isReviewed = node.isReviewed;
      final int score = node.score;
      
      // Animation Progress
      double nodeScale = 1.0;
      double nodeOpacity = 1.0;
      
      if (entranceProgress.containsKey(node.id)) {
        final t = entranceProgress[node.id]!;
        nodeScale = 0.8 + (0.2 * t);
        nodeOpacity = t;
      } else if (exitProgress.containsKey(node.id)) {
        final t = exitProgress[node.id]!;
        nodeScale = t;
        nodeOpacity = t;
      }
      
      // Thinking Lineage Color (Deterministic from Provider)
      // Drop Candy: High saturation (0.85) and max value (1.0)
      final Color baseColor = HSVColor.fromAHSV(1.0, node.hue, 0.85, 1.0).toColor();
      
      final ageHours = now.difference(node.date).inHours;
      final ageFactor = (1.0 - (ageHours / 168.0)).clamp(0.4, 1.0);
      

      // --- NEW CELESTIAL STAR DESIGN ---
      final double time = now.millisecondsSinceEpoch / 1000.0;
      final int seed = node.id.hashCode;
      final random = math.Random(seed);
      final double starDir = random.nextBool() ? 1.0 : -1.0;
      final double starSpeedMult = 0.7 + (random.nextDouble() * 0.8);
      
      // Twinkle Phase (used for diffraction spikes)
      final double twinkle = (math.sin(time * 2.5 * starSpeedMult + (seed % 100)) + 1) / 2;

      // Flicker Factor for unreviewed nodes (Staccato / Broken Bulb)
      double flickerFactor = 1.0;
      if (!isReviewed) {
        final double t = time + (seed % 100);
        double wobble = (math.sin(t * 2.5).abs() * 0.6) + (math.sin(t * 15.0).abs() * 0.2);
        final double staccato = math.sin(t * 30.0) * math.sin(t * 47.0);
        if (staccato > 0.5) {
          wobble *= 0.2;
        } else if (staccato < -0.85) {
          wobble = 0.02;
        }
        final double powerPulse = (math.sin(t * 0.6) + 1.0) / 2.0; 
        if (powerPulse < 0.25) {
           wobble *= (powerPulse * 4.0).clamp(0.1, 1.0);
        }
        flickerFactor = (wobble + 0.2).clamp(0.01, 1.0);
      }

      final double luminosity = isReviewed 
          ? (score == 5 ? 1.6 : (score == 3 ? 1.1 : 0.7))
          : 0.9; // Base luminosity for seeds

      // 0. Tiny Atmospheric Halo (Tight)
      final double baseRadius = (isReviewed ? (isSelected ? 5.0 : 4.0) : 3.0) * luminosity * ageFactor * nodeScale;
      final glowPaint = Paint()
        ..color = baseColor.withValues(alpha: 0.25 * (isReviewed ? 1.0 : flickerFactor) * nodeOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, baseRadius * 1.8);
      canvas.drawCircle(node.position, baseRadius * 1.5, glowPaint);

      // 1. Sparkle (Kirakira) Effect - Rare, Blurred & Rotating
      // Global orchestration: Period is long, offset by seed to distribute
      const double sparklePeriod = 54.0; // Reduced frequency (3x longer period)
      const double sparkleDuration = 0.8; 
      final double sparkleTimeRaw = (time + (seed % 100)) % sparklePeriod;
      
      if (sparkleTimeRaw < sparkleDuration && (isReviewed || isSelected)) {
        final double sparkleProgress = sparkleTimeRaw / sparkleDuration;
        final double sparkleIntensity = math.sin(sparkleProgress * math.pi);
        final double sparkleRotation = (time * 1.5) + (seed % 100);
        final double sparkleSize = (isSelected ? 32.0 : 22.0) * luminosity * ageFactor * sparkleIntensity;

        canvas.save();
        canvas.translate(node.position.dx, node.position.dy);
        canvas.rotate(sparkleRotation);

        final sparklePaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.7 * sparkleIntensity * ageFactor * nodeOpacity)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5); // Sharper edges than before

        final Path sparklePath = Path();
        // Sharper 4-pointed needle shape
        final double inset = sparkleSize * 0.08; 
        sparklePath.moveTo(0, -sparkleSize);
        sparklePath.quadraticBezierTo(inset, -inset, sparkleSize, 0);
        sparklePath.quadraticBezierTo(inset, inset, 0, sparkleSize);
        sparklePath.quadraticBezierTo(-inset, inset, -sparkleSize, 0);
        sparklePath.quadraticBezierTo(-inset, -inset, 0, -sparkleSize);
        sparklePath.close();

        canvas.drawPath(sparklePath, sparklePaint);

        // Center glow for the sparkle
        final sparkleCenterGlow = Paint()
          ..color = Colors.white.withValues(alpha: 0.5 * sparkleIntensity * nodeOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
        canvas.drawCircle(Offset.zero, sparkleSize * 0.3, sparkleCenterGlow);

        canvas.restore();
      }

      // 2. Orbital Satellites (Stardust) - Randomized Orbits & Speeds
      final int satelliteCount = node.isReviewed 
          ? (node.score == 5 ? 3 : (node.score == 3 ? 2 : 1)) 
          : 1;
      
      final satellitePaint = Paint()..color = Colors.white.withValues(
        alpha: 0.7 * (isReviewed ? 1.0 : flickerFactor) * ageFactor * nodeOpacity
      );

      for (int i = 0; i < satelliteCount; i++) {
        // Create a unique seed for each satellite for stable randomness
        final int satelliteSeed = seed ^ (i * 257);
        final math.Random satRandom = math.Random(satelliteSeed);
        
        // Randomized orbit radius: 1.8 to 6.5 times baseRadius
        // Increased range and lowered minimum to allow closer orbits and more spread
        final double satOrbitalRadius = baseRadius * (1.8 + satRandom.nextDouble() * 4.7);
        
        // Randomized speed: 0.5 to 1.3 of base speed
        final double satSpeed = (0.5 + satRandom.nextDouble() * 0.8) * 0.8 * starSpeedMult;
        
        // Use uniform direction for all satellites of this star
        
        // Randomized initial offset
        final double satOffset = satRandom.nextDouble() * math.pi * 2;
        
        final double angle = (time * satSpeed * starDir) + satOffset;
        final Offset satellitePos = node.position + Offset(
          math.cos(angle) * satOrbitalRadius,
          math.sin(angle) * satOrbitalRadius,
        );
        
        canvas.drawCircle(satellitePos, 0.8 * nodeScale, satellitePaint);
        final tinyGlow = Paint()
          ..color = Colors.white.withValues(alpha: 0.25 * nodeOpacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * nodeScale);
        canvas.drawCircle(satellitePos, 2.5 * nodeScale, tinyGlow);
      }

      // 4. Solid Core (Transitioning to White)
      final corePaint = Paint()..color = isReviewed 
          ? Color.lerp(baseColor, Colors.white, 0.3)!.withValues(alpha: nodeOpacity) 
          : baseColor.withValues(alpha: 0.7 * flickerFactor * nodeOpacity);
      canvas.drawCircle(node.position, baseRadius, corePaint);

      // White Hot Center
      final centerPaint = Paint()..color = Colors.white.withValues(
        alpha: (isReviewed ? 0.9 : 0.4 * flickerFactor) * ageFactor * nodeOpacity
      );
      canvas.drawCircle(node.position, baseRadius * (isReviewed ? 0.5 : 0.4), centerPaint);

      // 5. Atmospheric Ripple (Sonar Pulse) for Focus - Refined (Subtler)
      if (isSelected) {
        const double rippleDuration = 4.5;
        const int rippleCount = 2;
        
        for (int r = 0; r < rippleCount; r++) {
          // Stagger the ripples
          final double rippleOffset = r * (rippleDuration / rippleCount);
          final double rippleProgress = ((time + rippleOffset) % rippleDuration) / rippleDuration;
          
          // Cubic ease-out expansion
          final double easeOutProgress = 1.0 - math.pow(1.0 - rippleProgress, 3).toDouble();
          
          final double rippleRadius = baseRadius + (easeOutProgress * baseRadius * 12.0);
          final double rippleOpacity = (1.0 - rippleProgress) * 0.35 * nodeOpacity;
          
          final ripplePaint = Paint()
            ..color = Colors.cyanAccent.withValues(alpha: rippleOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0 * (1.0 - rippleProgress)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.5 * (1.0 - rippleProgress));
            
          canvas.drawCircle(node.position, rippleRadius, ripplePaint);
        }
      }

      // 6. Review Transition Pulse (Glow Effect)
      final double glow = glowProgress[node.id] ?? 0.0;
      if (glow > 0) {
        final double pulseRadius = baseRadius * (1.0 + glow * 8.0);
        final pulseGlowPaint = Paint()
          ..color = Colors.white.withValues(alpha: glow * 0.8)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15.0 * glow);
        canvas.drawCircle(node.position, pulseRadius, pulseGlowPaint);
        
        final pulseRingPaint = Paint()
          ..color = baseColor.withValues(alpha: glow * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(node.position, baseRadius * (2.0 + glow * 10.0), pulseRingPaint);
      }

      // 7. Sort-specific Labels (Date or Review Status)
      final labelText = _getSortLabel(node);

      if (labelText != null) {
        datePainter.text = TextSpan(
          text: labelText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 14,
            letterSpacing: 1,
            fontWeight: FontWeight.w400,
          ),
        );
        datePainter.layout();
        // Position on the left side
        datePainter.paint(canvas, node.position + Offset(-datePainter.width - 20, -datePainter.height / 2));
      }
    }
  }

  String? _getSortLabel(ConstellationNode node) {
    switch (sortMode) {
      case ConstellationSortMode.decisionDate:
        if (node.generation == 0) {
          return '${node.date.month}/${node.date.day}';
        }
        break;
      case ConstellationSortMode.latestActionDate:
        if (focusNodeIds.contains(node.id)) {
          return '${node.date.month}/${node.date.day}';
        }
        break;
      case ConstellationSortMode.unreviewedFirst:
        if (focusNodeIds.contains(node.id)) {
          return node.isReviewed ? '振り返り済み' : '未振り返り';
        }
        break;
      case ConstellationSortMode.reflectionDate:
        if (focusNodeIds.contains(node.id) && node.scheduledReflectionDate != null) {
          final d = node.scheduledReflectionDate!;
          return '${d.month}/${d.day}';
        }
        break;
      case ConstellationSortMode.none:
        break;
    }
    return null;
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
