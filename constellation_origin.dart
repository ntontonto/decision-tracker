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
  List<ConstellationNode> _focusedChainNodes = [];
  late PageController _pageController;
  bool _isAnimatingCamera = false;
  bool _isCardExpanded = false;
  bool _isCardVisible = false;
  
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
