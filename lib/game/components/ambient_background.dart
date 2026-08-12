import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Décor d'ambiance purement visuel : grille de sol animée + particules
/// flottantes lentes. Aucun impact sur le gameplay, juste pour donner
/// une sensation d'arène "vivante".
class AmbientBackground extends PositionComponent {
  final Random _rnd = Random();
  final List<_FloatingSpark> _sparks = [];
  double _gridScroll = 0;

  AmbientBackground({required Vector2 size}) : super(size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (int i = 0; i < 18; i++) {
      _sparks.add(_FloatingSpark(
        position:
            Vector2(_rnd.nextDouble() * size.x, _rnd.nextDouble() * size.y),
        speed: 8 + _rnd.nextDouble() * 14,
        radius: 1.5 + _rnd.nextDouble() * 2.5,
        opacity: 0.15 + _rnd.nextDouble() * 0.25,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _gridScroll = (_gridScroll + dt * 6) % 40;
    for (final spark in _sparks) {
      spark.position.y -= spark.speed * dt;
      if (spark.position.y < -10) {
        spark.position.y = size.y + 10;
        spark.position.x = _rnd.nextDouble() * size.x;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Grille douce qui défile lentement (sensation d'arène futuriste).
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    for (double x = -40 + _gridScroll; x < size.x; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = -40 + _gridScroll; y < size.y; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }

    // Particules flottantes douces (poussière d'énergie).
    for (final spark in _sparks) {
      final paint = Paint()
        ..color = const Color(0xFF41E0FF).withValues(alpha: spark.opacity);
      canvas.drawCircle(spark.position.toOffset(), spark.radius, paint);
    }

    // Léger vignettage pour focaliser l'attention sur le centre de l'arène.
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
        radius: 0.9,
      ).createShader(Rect.fromLTWH(0, 0, size.x, size.y));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), vignette);
  }
}

class _FloatingSpark {
  Vector2 position;
  final double speed;
  final double radius;
  final double opacity;

  _FloatingSpark({
    required this.position,
    required this.speed,
    required this.radius,
    required this.opacity,
  });
}
