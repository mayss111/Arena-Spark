import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum ObstacleType {
  energyBarrier, // Obstacle solide qui bloque les tirs et les déplacements
  bouncePad,     // Tremplin qui propulse le joueur/bot dans sa direction de déplacement
}

/// Obstacles tactiques répartis dans l'arène :
/// - Barrières d'énergie (couverture pour se protéger des tirs)
/// - Tremplins rétro-futuristes (boost instantané)
class Obstacle extends PositionComponent with HasGameReference {
  final ObstacleType type;
  double _pulsePhase = 0;

  Obstacle({
    required Vector2 position,
    required this.type,
    Vector2? size,
  }) : super(
          position: position,
          size: size ?? (type == ObstacleType.energyBarrier ? Vector2(60, 24) : Vector2(40, 40)),
          anchor: Anchor.center,
        ) {
    _pulsePhase = Random().nextDouble() * pi * 2;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (type == ObstacleType.energyBarrier) {
      add(RectangleHitbox(isSolid: true)..collisionType = CollisionType.passive);
    } else {
      add(CircleHitbox(isSolid: true)..collisionType = CollisionType.passive);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulsePhase += dt * 3;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final pulse = (sin(_pulsePhase) * 0.2 + 0.8);

    if (type == ObstacleType.energyBarrier) {
      // Barrière d'énergie rectangulaire lumineuse
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(8),
      );

      final bgPaint = Paint()..color = const Color(0xFF1E2942);
      canvas.drawRRect(rrect, bgPaint);

      final borderPaint = Paint()
        ..color = const Color(0xFF41E0FF).withValues(alpha: 0.7 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(rrect, borderPaint);

      final glowPaint = Paint()
        ..color = const Color(0xFF41E0FF).withValues(alpha: 0.2 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(rrect, glowPaint);

      // Motif hachuré futuriste
      final linePaint = Paint()
        ..color = const Color(0xFF41E0FF).withValues(alpha: 0.3)
        ..strokeWidth = 1.5;
      for (double x = 8; x < size.x - 4; x += 12) {
        canvas.drawLine(Offset(x, 4), Offset(x + 6, size.y - 4), linePaint);
      }
    } else {
      // Tremplin (Bounce Pad) rond avec flèche lumineuse
      final center = Offset(size.x / 2, size.y / 2);
      final radius = size.x / 2;

      final bgPaint = Paint()..color = const Color(0xFFFFD166).withValues(alpha: 0.25);
      canvas.drawCircle(center, radius, bgPaint);

      final ringPaint = Paint()
        ..color = const Color(0xFFFFD166).withValues(alpha: 0.8 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, radius - 2, ringPaint);

      // Icône tremplin / flèche
      final tp = TextPainter(
        text: const TextSpan(text: '🚀', style: TextStyle(fontSize: 20)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
    }
  }
}
