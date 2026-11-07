// app_theme.dart
// Premium dark medical UI — deep space aesthetic with surgical precision.
// Inspired by high-end ICU monitor interfaces + sci-fi HUD design.

import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ── Core Palette ───────────────────────────────────────────────────────
  static const Color bg0         = Color(0xFF060A14); // deepest background
  static const Color bg1         = Color(0xFF0A1020); // main scaffold
  static const Color bg2         = Color(0xFF0F1828); // card base
  static const Color bg3         = Color(0xFF162035); // elevated card
  static const Color bg4         = Color(0xFF1C2940); // active/hover state

  // Accent neons
  static const Color cyan        = Color(0xFF00D9FF);
  static const Color cyanDim     = Color(0xFF0099BB);
  static const Color green       = Color(0xFF00FF88);
  static const Color greenDim    = Color(0xFF00AA55);
  static const Color yellow      = Color(0xFFFFCC00);
  static const Color yellowDim   = Color(0xFFAA8800);
  static const Color red         = Color(0xFFFF2D55);
  static const Color redDim      = Color(0xFFAA1133);
  static const Color purple      = Color(0xFFBB44FF);
  static const Color purpleDim   = Color(0xFF7722AA);
  static const Color orange      = Color(0xFFFF8800);

  // Text
  static const Color textPrimary   = Color(0xFFEEF4FF);
  static const Color textSecondary = Color(0xFF6A84AA);
  static const Color textTertiary  = Color(0xFF3A5070);
  static const Color divider       = Color(0xFF162030);

  // ── Gradients ──────────────────────────────────────────────────────────
  static const LinearGradient cyanGrad = LinearGradient(
    colors: [cyan, Color(0xFF0066FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGrad = LinearGradient(
    colors: [red, Color(0xFFFF6600)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGrad = LinearGradient(
    colors: [green, Color(0xFF00AAFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleGrad = LinearGradient(
    colors: [purple, Color(0xFF4444FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── ThemeData ──────────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg1,
    fontFamily: 'Courier', // monospace feels medical/technical
    colorScheme: const ColorScheme.dark(
      surface: bg2,
      primary: cyan,
      error: red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: 2,
        fontFamily: 'Courier',
      ),
      iconTheme: IconThemeData(color: cyan),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bg2,
      selectedItemColor: cyan,
      unselectedItemColor: textTertiary,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
      unselectedLabelStyle: TextStyle(fontSize: 10, letterSpacing: 0.5),
    ),
  );

  // ── Reusable decorations ───────────────────────────────────────────────

  static BoxDecoration glassCard({
    Color borderColor = cyan,
    double borderOpacity = 0.25,
    double glowOpacity = 0.06,
    double radius = 20,
  }) =>
      BoxDecoration(
        color: bg2,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
            color: borderColor.withValues(alpha: borderOpacity), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: glowOpacity),
            blurRadius: 24,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: bg0.withValues(alpha: 0.6),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration gradientCard(LinearGradient gradient,
      {double radius = 20}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: (gradient.colors.first).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      );

  // Scanline overlay painter for the HUD feel
  static Widget scanlineOverlay({double opacity = 0.03}) => Positioned.fill(
    child: IgnorePointer(
      child: CustomPaint(painter: _ScanlinePainter(opacity)),
    ),
  );
}

/// Paints subtle horizontal scanlines for a monitor/HUD aesthetic
class _ScanlinePainter extends CustomPainter {
  final double opacity;
  _ScanlinePainter(this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => old.opacity != opacity;
}
