import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/enums.dart';
import '../theme/app_design.dart';

class WizardReflectionStep extends StatefulWidget {
  final ValueItem? selectedGain;
  final ValueItem? selectedLose;
  final Function(ValueItem?) onGainSelect;
  final Function(ValueItem?) onLoseSelect;
  final VoidCallback? onComplete;

  const WizardReflectionStep({
    super.key,
    this.selectedGain,
    this.selectedLose,
    required this.onGainSelect,
    required this.onLoseSelect,
    this.onComplete,
  });

  @override
  State<WizardReflectionStep> createState() => _WizardReflectionStepState();
}

class _WizardReflectionStepState extends State<WizardReflectionStep> with TickerProviderStateMixin {
  bool _isGainHovering = false;
  bool _isLoseHovering = false;
  
  // Focus management
  String _activeFocus = 'lose'; // 'lose' or 'gain'
  
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Auto-focus logic: if Lose is already set, focus Gain
    if (widget.selectedLose != null && widget.selectedGain == null) {
      _activeFocus = 'gain';
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text('どんな価値の交換だと思う？', style: AppDesign.titleStyle.copyWith(fontSize: 22)),
          Text(
            _activeFocus == 'lose' ? 'まずは「失ったもの」を選択してください' : '次に「得たもの」を選択してください',
            style: AppDesign.subtitleStyle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          // Sockets Area
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocket(
                title: '失ったもの (-)',
                selected: widget.selectedLose,
                isLose: true,
                isHovering: _isLoseHovering,
                isActive: _activeFocus == 'lose',
                onHover: (h) => setState(() => _isLoseHovering = h),
                onAccept: (item) {
                  widget.onLoseSelect(item);
                  setState(() => _activeFocus = 'gain');
                  _checkAutoNavigate();
                },
                onClear: () {
                  widget.onLoseSelect(null);
                  setState(() => _activeFocus = 'lose');
                },
                onTap: () => setState(() => _activeFocus = 'lose'),
              ),
              _buildSocket(
                title: '得たもの (+)',
                selected: widget.selectedGain,
                isLose: false,
                isHovering: _isGainHovering,
                isActive: _activeFocus == 'gain',
                onHover: (h) => setState(() => _isGainHovering = h),
                onAccept: (item) {
                  widget.onGainSelect(item);
                  _checkAutoNavigate();
                },
                onClear: () {
                  widget.onGainSelect(null);
                  setState(() => _activeFocus = 'gain');
                },
                onTap: () => setState(() => _activeFocus = 'gain'),
              ),
            ],
          ),
          
          const SizedBox(height: 48),
          
          // Unified Selection Area
          _buildUnifiedItemSection(
            items: ValueItem.values,
          ),
          
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSocket({
    required String title,
    required ValueItem? selected,
    required bool isLose,
    required bool isHovering,
    required bool isActive,
    required Function(bool) onHover,
    required Function(ValueItem) onAccept,
    required VoidCallback onClear,
    required VoidCallback onTap,
  }) {
    final isSelected = selected != null;
    final color = isLose ? Colors.redAccent : Colors.greenAccent;

    return Column(
      children: [
        Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DragTarget<ValueItem>(
          onWillAcceptWithDetails: (details) {
            onHover(true);
            HapticFeedback.selectionClick();
            return true;
          },
          onLeave: (data) => onHover(false),
          onAcceptWithDetails: (details) {
            onHover(false);
            HapticFeedback.mediumImpact();
            onAccept(details.data);
          },
          builder: (context, candidateData, rejectedData) {
            return AnimatedScale(
              scale: isHovering ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: () {
                  if (isSelected) {
                    onClear();
                  } else {
                    onTap();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color.withOpacity(0.2) : (isActive ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.05)),
                    border: Border.all(
                      color: isSelected ? color : (isActive ? color.withOpacity(0.5) : (isHovering ? Colors.white : Colors.white24)),
                      width: isSelected || isHovering || isActive ? 3 : 1,
                    ),
                    boxShadow: [
                      if (isHovering || isSelected || isActive)
                        BoxShadow(
                          color: isSelected ? color.withOpacity(0.3) : (isActive ? color.withOpacity(0.2) : Colors.white.withOpacity(0.2)),
                          blurRadius: isSelected ? 20 : (isActive ? 15 : 10),
                          spreadRadius: isSelected ? 5 : (isActive ? 2 : 0),
                        ),
                    ],
                  ),
                  child: Center(
                    child: isSelected
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(selected.icon, color: Colors.white, size: 28),
                            const SizedBox(height: 2),
                            Text(
                              selected.label,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : ScaleTransition(
                          scale: Tween(begin: 1.0, end: 1.05).animate(_pulseController),
                          child: Icon(
                            isLose ? Icons.remove_circle_outline : Icons.add_circle_outline,
                            color: Colors.white24,
                            size: 40,
                          ),
                        ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUnifiedItemSection({
    required List<ValueItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text('価値の項目', style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            final isGainSelected = widget.selectedGain == item;
            final isLoseSelected = widget.selectedLose == item;
            
            return Draggable<ValueItem>(
              data: item,
              feedback: Material(
                color: Colors.transparent,
                child: _ItemChip(
                  label: item.label,
                  icon: item.icon,
                  isSelectedAsGain: isGainSelected,
                  isSelectedAsLose: isLoseSelected,
                  dragging: true,
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _ItemChip(
                  label: item.label,
                  icon: item.icon,
                  isSelectedAsGain: isGainSelected,
                  isSelectedAsLose: isLoseSelected,
                ),
              ),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _handleCycleTap(item);
                },
                child: _ItemChip(
                  label: item.label,
                  icon: item.icon,
                  isSelectedAsGain: isGainSelected,
                  isSelectedAsLose: isLoseSelected,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _handleCycleTap(ValueItem item) {
    if (widget.selectedGain == item) {
      widget.onGainSelect(null);
      setState(() => _activeFocus = 'gain');
    } else if (widget.selectedLose == item) {
      widget.onLoseSelect(null);
      setState(() => _activeFocus = 'lose');
    } else {
      if (_activeFocus == 'lose') {
        widget.onLoseSelect(item);
        setState(() => _activeFocus = 'gain');
      } else {
        widget.onGainSelect(item);
      }
    }
    
    _checkAutoNavigate();
  }

  void _checkAutoNavigate() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && widget.selectedGain != null && widget.selectedLose != null) {
        widget.onComplete?.call();
      }
    });
  }
}

class _ItemChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool dragging;
  final bool isSelectedAsGain;
  final bool isSelectedAsLose;

  const _ItemChip({
    required this.label,
    required this.icon,
    this.dragging = false,
    this.isSelectedAsGain = false,
    this.isSelectedAsLose = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelectedAsLose ? Colors.redAccent : (isSelectedAsGain ? Colors.greenAccent : Colors.white12);
    final isSelected = isSelectedAsGain || isSelectedAsLose;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.3) : AppDesign.glassBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? color : Colors.white12),
        boxShadow: [
          if (dragging || isSelected)
            BoxShadow(
              color: isSelected ? color.withOpacity(0.2) : Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
