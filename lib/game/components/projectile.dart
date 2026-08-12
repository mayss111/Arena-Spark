import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'projectile_trail.dart';

class Projectile extends CircleComponent
    with CollisionCallbacks, HasGameReference {
  final Vector2 direction;
  final double speed;
  final bool fromPlayer;
  final int damage;
  final Color color;
  final bool isSniper;
  final bool isRocket;
  static const double baseLifeSpan = 1.6;

  double _age = 0;
  double _trailTimer = 0;
  late final ProjectileTrail _trail;
  double _spinTimer = 0;

  Projectile({
    required Vector2 position,
    required this.direction,
    required this.fromPlayer,
    this.speed = 420,
    this.damage = 1,
    Color? color,
    this.isSniper = false,
    this.isRocket = false,
  })  : color = color ??
            (fromPlayer ? const Color(0xFF41E0FF) : const Color(0xFFFF6B6B)),
        super(
          position: position,
          radius: isRocket
              ? 10
              : (isSniper ? 9 : 7),
          anchor: Anchor.center,
          paint: Paint()
            ..color = color ??
                (fromPlayer
                    ? const Color(0xFF41E0FF)
                    : const Color(0xFFFF6B6B)),
        );

  double get lifeSpan => isSniper ? 2.2 : (isRocket ? 1.2 : baseLifeSpan);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(isSolid: true)..collisionType = CollisionType.passive);

    add(
      CircleComponent(
        radius: radius * (isRocket ? 2.8 : 2.0),
        anchor: Anchor.center,
        position: size / 2,
        paint: Paint()
          ..color = color.withValues(alpha: isRocket ? 0.35 : 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      ),
    );

    if (isSniper) {
      add(CircleComponent(
        radius: radius * 1.4,
        anchor: Anchor.center,
        position: size / 2,
        paint: Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      ));
    }

    _trail = ProjectileTrail(
      color: color,
    );
    parent?.add(_trail);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction.normalized() * speed * dt;
    _age += dt;
    _spinTimer += dt;

    _trailTimer += dt;
    if (_trailTimer >= (isSniper ? 0.008 : 0.015)) {
      _trailTimer = 0;
      _trail.recordPosition(position);
    }

    if (isRocket) {
      paint.color = Color.lerp(
        color,
        Colors.yellow,
        (sin(_spinTimer * 12) * 0.5 + 0.5),
      )!;
    }

    if (_age >= lifeSpan) {
      _trail.removeFromParent();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (isSniper) {
      final angle = atan2(direction.y, direction.x);
      final trailPaint = Paint()
        ..color = color.withValues(alpha: 0.7)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(size.x / 2 - cos(angle) * 22, size.y / 2 - sin(angle) * 22),
        Offset(size.x / 2, size.y / 2),
        trailPaint,
      );
    }

    if (isRocket) {
      final finPaint = Paint()..color = Colors.deepOrange;
      final angle = atan2(direction.y, direction.x);
      for (int i = 0; i < 4; i++) {
        final a = angle + i * pi / 2 + _spinTimer * 3;
        canvas.drawCircle(
          Offset(size.x / 2 + cos(a) * 14, size.y / 2 + sin(a) * 14),
          3,
          finPaint,
        );
      }
    }
  }

  @override
  void onRemove() {
    if (_trail.isMounted) {
      _trail.removeFromParent();
    }
    super.onRemove();
  }
}
