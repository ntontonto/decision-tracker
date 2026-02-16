import 'package:flutter/material.dart';

class AppDesign {
  // --- Glassmorphism ---
  static const double glassBlur = 12.0;
  
  // "Semi-transparent grey background" look
  // Using a soft white/grey with 12% alpha to create visibility on black background
  static final Color glassBackgroundColor = const Color(0xFFFFFFFF).withValues(alpha: 0.12);
  static final Color glassBorderColor = const Color(0xFFFFFFFF).withValues(alpha: 0.15);
  static const double glassBorderWidth = 0.5;

  static BoxDecoration glassDecoration({
    double borderRadius = 16.0,
    bool showBorder = true,
  }) {
    return BoxDecoration(
      color: glassBackgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: showBorder 
        ? Border.all(color: glassBorderColor, width: glassBorderWidth)
        : null,
    );
  }

  // --- Button Styles ---
  static BoxDecoration actionButtonDecoration({bool selected = false}) {
    return BoxDecoration(
      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(30),
    );
  }

  static TextStyle actionButtonTextStyle({bool selected = false}) {
    return TextStyle(
      color: selected ? Colors.black : Colors.white,
      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      fontSize: 16,
    );
  }

  // --- Indicator & Feedback ---
  static const Color indicatorActiveColor = Colors.white;
  static final Color indicatorInactiveColor = Colors.white.withValues(alpha: 0.15);
  static final Color errorGlowColor = Colors.red.withValues(alpha: 0.4);

  // --- Input Styles ---
  static InputDecoration inputDecoration({
    required String hintText,
    bool isLarge = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white24),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white30, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16, 
        vertical: isLarge ? 20 : 12,
      ),
    );
  }

  // --- Colors (ChatGPT Style) ---
  static const Color darkBackground = Colors.black;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color textMuted = Colors.white38;

  // --- Typography ---
  static const TextStyle titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 12,
    color: textMuted,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: textPrimary,
    fontWeight: FontWeight.w600,
  );

  // --- Card Styles ---
  static BoxDecoration cardDecoration({
    double borderRadius = 16.0,
  }) {
    return BoxDecoration(
      color: glassBackgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: glassBorderColor, width: glassBorderWidth),
    );
  }

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: textMuted,
    letterSpacing: 0.8,
  );

  static const TextStyle valueLabelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}
