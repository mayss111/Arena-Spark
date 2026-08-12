import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'power_up.dart';
import '../spark_arena_game.dart';

/// Airdrop parachuté du ciel (DNA Battle Royale Free Fire).
/// Faisceau lumineux d'avertissement -> Caisse dorée qui atterrit -> Loot épique !
class AirDrop extends PositionComponent with HasGameReference<SparkArenaGame> {
  final Vector2 targetPosition;
  double _dropProgress = 0;
  bool landed = false;
  bool opened = false;
  double _pulse = 0;

  static const double dropDuration = 2.5;

  AirDrop({required this.targetPosition})
      : super(
          position: targetPosition.clone()..y -= 300,
          size: Vector2.all(38),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(isSolid: true)..collisionType = CollisionType.passive);
  }

  void open() {
    if (opened || !landed) return;
    opened = true;

    final rnd = Random();

    game.add(PowerUp(
      position: targetPosition + Vector2(25, 0),
      type: PowerUpType.shield,
    ));

    final extraTypes = [PowerUpType.doubleFire, PowerUpType.speed, PowerUpType.heal];
    game.add(PowerUp(
      position: targetPosition + Vector2(-25, 0),
      type: extraTypes[rnd.nextInt(extraTypes.length)],
    ));

    game.scoreManager.score += 150;

    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulse += dt * 4;

    if (!landed) {
      _dropProgress += dt / dropDuration;
      if (_dropProgress >= 1.0) {
        _dropProgress = 1.0;
        landed = true;
        position = targetPosition;
        game.shakeCamera(strength: 6, duration: 0.2);
      } else {
        position = Vector2(
          targetPosition.x,
          targetPosition.y - 300 * (1 - _dropProgress),
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset(size.x / 2, size.y / 2);
    final pulseFactor = sin(_pulse) * 0.2 + 0.8;

    if (!opened) {
      final beamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.0),
            const Color(0xFFFFD700).withValues(alpha: 0.35 * pulseFactor),
          ],
        ).createShader(Rect.fromLTWH(-10, -500, size.x + 20, 500));
      canvas.drawRect(Rect.fromLTWH(-10, -500, size.x + 20, 500), beamPaint);
    }

    if (!landed) {
      final chutePaint = Paint()..color = const Color(0xFFFF6347);
      final path = Path()
        ..moveTo(-10, -15)
        ..quadraticBezierTo(size.x / 2, -45, size.x + 10, -15)
        ..close();
      canvas.drawPath(path, chutePaint);

      final linePaint = Paint()
        ..color = Colors.white70
        ..strokeWidth = 1.2;
      canvas.drawLine(const Offset(-8, -15), center, linePaint);
      canvas.drawLine(Offset(size.x + 8, -15), center, linePaint);
    }

    final boxRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(8),
    );

    final boxPaint = Paint()..color = const Color(0xFFFFB703);
    canvas.drawRRect(boxRect, boxPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(boxRect, borderPaint);

    final ribbonPaint = Paint()..color = const Color(0xFFD62828);
    canvas.drawRect(Rect.fromLTWH(size.x / 2 - 4, 0, 8, size.y), ribbonPaint);
    canvas.drawRect(Rect.fromLTWH(0, size.y / 2 - 4, size.x, 8), ribbonPaint);

    final tp = TextPainter(
      text: const TextSpan(text: '📦', style: TextStyle(fontSize: 20)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }
}
