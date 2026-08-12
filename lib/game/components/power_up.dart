import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum PowerUpType {
  shield,
  doubleFire,
  speed,
  heal,
  damage,
}

class PowerUp extends PositionComponent with HasGameReference {
  final PowerUpType type;

  static const double despawnTime = 20.0;
  static const double _floatAmplitude = 4.0;
  static const double _floatSpeed = 3.0;
  static const double _baseRadius = 16.0;

  double _age = 0;
  double _floatPhase = 0;
  final double _initialPhase;
  bool collected = false;

  static Color colorForType(PowerUpType type) {
    switch (type) {
      case PowerUpType.shield:
        return const Color(0xFF7B68EE);
      case PowerUpType.doubleFire:
        return const Color(0xFFFFD700);
      case PowerUpType.speed:
        return const Color(0xFF41E0FF);
      case PowerUpType.heal:
        return const Color(0xFF4CAF50);
      case PowerUpType.damage:
        return const Color(0xFFFF4500);
    }
  }

  static String iconForType(PowerUpType type) {
    switch (type) {
      case PowerUpType.shield:
        return '🛡';
      case PowerUpType.doubleFire:
        return '✨';
      case PowerUpType.speed:
        return '💨';
      case PowerUpType.heal:
        return '💚';
      case PowerUpType.damage:
        return '💪';
    }
  }

  static String nameForType(PowerUpType type) {
    switch (type) {
      case PowerUpType.shield:
        return 'Bouclier';
      case PowerUpType.doubleFire:
        return 'Double Tir';
      case PowerUpType.speed:
        return 'Vitesse';
      case PowerUpType.heal:
        return 'Soin';
      case PowerUpType.damage:
        return 'Dégâts +50%';
    }
  }

  PowerUp({
    required Vector2 position,
    required this.type,
  })  : _initialPhase = Random().nextDouble() * pi * 2,
        super(
          position: position,
          size: Vector2.all(_baseRadius * 2),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(isSolid: true)..collisionType = CollisionType.passive);
  }

  void collect() {
    collected = true;
    removeFromParent();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    _floatPhase += dt;

    if (_age >= despawnTime && !collected) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final color = colorForType(type);
    final center = Offset(size.x / 2, size.y / 2);
    final floatOffset =
        sin(_floatPhase * _floatSpeed + _initialPhase) * _floatAmplitude;
    final drawCenter = center.translate(0, floatOffset);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(drawCenter, _baseRadius * 1.8, glowPaint);

    final starCount = type == PowerUpType.damage ? 5 : 1;
    const starR = _baseRadius * 1.4;
    for (int i = 0; i < starCount; i++) {
      final starAngle = i * 2 * pi / starCount + _floatPhase;
      final starC = drawCenter.translate(cos(starAngle) * starR * 0.2,
          sin(starAngle) * starR * 0.2 - 2);
      final starPaint = Paint()
        ..color = color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(starC, _baseRadius * 1.1, starPaint);
    }

    final mainPaint = Paint()..color = color.withValues(alpha: 0.88);
    canvas.drawCircle(drawCenter, _baseRadius * 0.85, mainPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(drawCenter, _baseRadius * 0.85, borderPaint);

    final innerPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawCircle(drawCenter, _baseRadius * 0.35, innerPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: iconForType(type),
        style: const TextStyle(fontSize: 16),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(drawCenter.dx - textPainter.width / 2,
          drawCenter.dy - textPainter.height / 2),
    );

    if (_age > despawnTime - 4) {
      final blink = sin(_age * 8) > 0;
      if (!blink) {
        final fadePaint = Paint()..color = Colors.black.withValues(alpha: 0.4);
        canvas.drawCircle(drawCenter, _baseRadius * 0.9, fadePaint);
      }
    }
  }
}
