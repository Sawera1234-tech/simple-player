import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_themes.dart';

/// Poori app ke peeche lagne wala art background.
class ArtBackground extends StatelessWidget {
  final AppThemeData theme;
  final Widget child;
  const ArtBackground({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: theme.gradient,
            ),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(painter: _ArtPainter(theme.art)),
        ),
        child,
      ],
    );
  }
}

class _ArtPainter extends CustomPainter {
  final ArtKind kind;
  _ArtPainter(this.kind);

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case ArtKind.sunset:
        _sunset(canvas, size);
      case ArtKind.night:
        _night(canvas, size);
      case ArtKind.sakura:
        _sakura(canvas, size);
      case ArtKind.ocean:
        _ocean(canvas, size);
      case ArtKind.forest:
        _forest(canvas, size);
      case ArtKind.minimalDark:
        _minimal(canvas, size);
    }
  }

  // ---------- Sunset: bara sooraj + pahari silsile ----------
  void _sunset(Canvas c, Size s) {
    final sun = Offset(s.width * 0.5, s.height * 0.62);
    c.drawCircle(
      sun,
      s.width * 0.34,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFE29A).withOpacity(0.95),
          const Color(0xFFFF9A5A).withOpacity(0.35),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: sun, radius: s.width * 0.5)),
    );
    _hills(c, s, s.height * 0.78, const Color(0xFF5B2A66), 0.55, 0);
    _hills(c, s, s.height * 0.86, const Color(0xFF2E1245), 0.7, 1.7);
    _hills(c, s, s.height * 0.94, const Color(0xFF160826), 0.85, 3.1);
  }

  void _hills(Canvas c, Size s, double base, Color color, double amp, double phase) {
    final p = Path()..moveTo(0, s.height);
    for (double x = 0; x <= s.width; x += 6) {
      final y = base -
          math.sin(x / s.width * math.pi * 2 + phase) * 26 * amp -
          math.sin(x / s.width * math.pi * 5 + phase) * 9 * amp;
      p.lineTo(x, y);
    }
    p
      ..lineTo(s.width, s.height)
      ..close();
    c.drawPath(p, Paint()..color = color.withOpacity(0.92));
  }

  // ---------- Starry night: taaray + chaand ----------
  void _night(Canvas c, Size s) {
    final rnd = math.Random(7);
    for (int i = 0; i < 90; i++) {
      final r = rnd.nextDouble() * 1.6 + 0.4;
      c.drawCircle(
        Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * 0.8),
        r,
        Paint()..color = Colors.white.withOpacity(0.35 + rnd.nextDouble() * 0.6),
      );
    }
    final moon = Offset(s.width * 0.78, s.height * 0.14);
    c.drawCircle(
      moon,
      70,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withOpacity(0.35),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: moon, radius: 70)),
    );
    c.drawCircle(moon, 26, Paint()..color = const Color(0xFFFFF6D6));
    c.drawCircle(
      moon.translate(10, -6),
      24,
      Paint()..color = const Color(0xFF0E1440),
    );
    _hills(c, s, s.height * 0.92, const Color(0xFF080B26), 0.6, 0.8);
  }

  // ---------- Sakura: gulabi phool ki pankhriyan ----------
  void _sakura(Canvas c, Size s) {
    final rnd = math.Random(11);
    for (int i = 0; i < 38; i++) {
      final pos = Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height);
      final size = 8 + rnd.nextDouble() * 14;
      final angle = rnd.nextDouble() * math.pi * 2;
      _petal(c, pos, size, angle,
          const Color(0xFFFF7FAE).withOpacity(0.25 + rnd.nextDouble() * 0.4));
    }
    // upar ki tehni
    final branch = Paint()
      ..color = const Color(0xFF8A5A5A).withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(s.width * 1.05, s.height * 0.05)
      ..quadraticBezierTo(s.width * 0.7, s.height * 0.08, s.width * 0.45, s.height * 0.03);
    c.drawPath(path, branch);
    for (int i = 0; i < 9; i++) {
      final t = i / 8;
      final p = Offset(s.width * (1.0 - t * 0.55), s.height * (0.055 + math.sin(t * 3) * 0.015));
      _blossom(c, p, 13 + (i % 3) * 3.0);
    }
  }

  void _petal(Canvas c, Offset o, double r, double a, Color col) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(a);
    final p = Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(r * 0.9, -r * 0.2, 0, r)
      ..quadraticBezierTo(-r * 0.9, -r * 0.2, 0, -r);
    c.drawPath(p, Paint()..color = col);
    c.restore();
  }

  void _blossom(Canvas c, Offset o, double r) {
    for (int i = 0; i < 5; i++) {
      _petal(c, o + Offset.fromDirection(i * math.pi * 2 / 5, r * 0.6), r * 0.7,
          i * math.pi * 2 / 5 + math.pi / 2, const Color(0xFFFF8DB6).withOpacity(0.85));
    }
    c.drawCircle(o, r * 0.18, Paint()..color = const Color(0xFFFFE08A));
  }

  // ---------- Ocean: lehrein + bubbles ----------
  void _ocean(Canvas c, Size s) {
    for (int w = 0; w < 4; w++) {
      final base = s.height * (0.72 + w * 0.07);
      final p = Path()..moveTo(0, s.height);
      for (double x = 0; x <= s.width; x += 5) {
        p.lineTo(x, base + math.sin(x / s.width * math.pi * (3 + w) + w) * (10 + w * 3));
      }
      p
        ..lineTo(s.width, s.height)
        ..close();
      c.drawPath(p, Paint()..color = Colors.white.withOpacity(0.05 + w * 0.03));
    }
    final rnd = math.Random(5);
    for (int i = 0; i < 22; i++) {
      c.drawCircle(
        Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height),
        2 + rnd.nextDouble() * 7,
        Paint()
          ..color = Colors.white.withOpacity(0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  // ---------- Forest: darakht + jugnu ----------
  void _forest(Canvas c, Size s) {
    final rnd = math.Random(3);
    for (int layer = 0; layer < 3; layer++) {
      final col = Color.lerp(const Color(0xFF1F6B4A), const Color(0xFF04140E), layer / 2)!;
      for (double x = -20; x < s.width + 40; x += 38 + layer * 14) {
        final h = 90 + rnd.nextDouble() * 80 + layer * 30;
        final baseY = s.height * (0.80 + layer * 0.07);
        final tree = Path()
          ..moveTo(x, baseY - h)
          ..lineTo(x + 26, baseY)
          ..lineTo(x - 26, baseY)
          ..close();
        c.drawPath(tree, Paint()..color = col.withOpacity(0.9));
      }
    }
    for (int i = 0; i < 26; i++) {
      final o = Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * 0.8);
      c.drawCircle(o, 6, Paint()..color = const Color(0xFFFFF59D).withOpacity(0.12));
      c.drawCircle(o, 1.8, Paint()..color = const Color(0xFFFFF59D).withOpacity(0.85));
    }
  }

  // ---------- Simple dark: halki si glow ----------
  void _minimal(Canvas c, Size s) {
    final o = Offset(s.width * 0.8, s.height * 0.1);
    c.drawCircle(
      o,
      s.width * 0.6,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFF9C7BFF).withOpacity(0.18),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: o, radius: s.width * 0.6)),
    );
  }

  @override
  bool shouldRepaint(covariant _ArtPainter old) => old.kind != kind;
}
