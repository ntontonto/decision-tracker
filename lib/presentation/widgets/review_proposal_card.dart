import 'package:flutter/material.dart';
import '../../domain/models/reviewable.dart';
import '../theme/app_design.dart';

import 'dart:async';

class ReviewProposalCard extends StatefulWidget {
  final Reviewable item;
  final VoidCallback onTap;
  final int? refreshTrigger;

  const ReviewProposalCard({
    super.key,
    required this.item,
    required this.onTap,
    this.refreshTrigger,
  });

  @override
  State<ReviewProposalCard> createState() => _ReviewProposalCardState();
}

class _ReviewProposalCardState extends State<ReviewProposalCard> {
  String _displayTitle = '';
  String _displayDescription = '';
  Timer? _typeTimer;
  bool _isCursorVisible = true;
  Timer? _cursorTimer;

  @override
  void initState() {
    super.initState();
    _startCursorBlink();
    _startTypewriter(widget.item.title, widget.item.description);
  }

  @override
  void didUpdateWidget(ReviewProposalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.title != widget.item.title || 
        oldWidget.item.description != widget.item.description ||
        oldWidget.refreshTrigger != widget.refreshTrigger) {
      _startTypewriter(widget.item.title, widget.item.description);
    }
  }

  @override
  void dispose() {
    _typeTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _isCursorVisible = !_isCursorVisible;
      });
    });
  }

  Future<void> _startTypewriter(String targetTitle, String targetDescription) async {
    _typeTimer?.cancel();

    // 1. Erase current description if it exists
    while (_displayDescription.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 20));
      if (!mounted) return;
      setState(() {
        _displayDescription = _displayDescription.substring(0, _displayDescription.length - 1);
      });
    }

    // 2. Erase current title if it exists
    while (_displayTitle.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted) return;
      setState(() {
        _displayTitle = _displayTitle.substring(0, _displayTitle.length - 1);
      });
    }

    // 3. Type new title
    for (int i = 0; i <= targetTitle.length; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      setState(() {
        _displayTitle = targetTitle.substring(0, i);
      });
    }

    // 4. Type new description
    for (int i = 0; i <= targetDescription.length; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() {
        _displayDescription = targetDescription.substring(0, i);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cursor = _isCursorVisible ? '|' : ' ';
    
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: AppDesign.glassBackgroundColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: widget.item.isReviewableNow 
                ? Colors.white.withValues(alpha: 0.4) 
                : Colors.white.withValues(alpha: 0.15),
            width: 0.5,
          ),
          boxShadow: widget.item.isReviewableNow
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ]
            : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  widget.item.icon,
                  size: 14,
                  color: AppDesign.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$_displayTitle${_displayDescription.isEmpty ? cursor : ""}',
                    style: AppDesign.subtitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$_displayDescription${_displayDescription.isNotEmpty ? cursor : ""}',
                    style: AppDesign.bodyStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
