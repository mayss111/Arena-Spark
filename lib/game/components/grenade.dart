import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../spark_arena_game.dart';
import 'impact_sparks.dart';
import 'shockwave.dart';

/// Grenade — projectile qui rebondit et explose après un délai.
class Grenade extends PositionComponent with HasGameReference<SparkArenaGame> {
  final Vector2 direction;

  static const double speed = 280;
  static const double fuseTime = 1.8;
  static const double blastRadius = 90;
  static const int blastDamage = 2;

  double _age = 0;
  Vector2 _velocity;
  double _rotation = 0;
  bool _exploded = false;

  Grenade({
    required Vector2 position,
    required this.direction,
  })  : _velocity = direction.normalized() * speed,
        super(
          position: position,
          size: Vector2.all(12),
          anchor: Anchor.center,
        );

  @override
  void update(double dt) {
    if (_exploded) return;
    _age += dt;
    _rotation += 8 * dt;

    // Mouvement
    position += _velocity * dt;
    _velocity *= (1 - 1.5 * dt).clamp(0.0, 1.0);

    // Rebond sur les bords
    final sz = game.size;
    if (position.x < 10 || position.x > sz.x - 10) {
      _velocity.x = -_velocity.x * 0.7;
      position.x = position.x.clamp(10, sz.x - 10);
    }
    if (position.y < 10 || position.y > sz.y - 10) {
      _velocity.y = -_velocity.y * 0.7;
      position.y = position.y.clamp(10, sz.y - 10);
    }

    if (_age >= fuseTime) {
      _explode();
    }
  }

  void _explode() {
    _exploded = true;

    parent?.add(Shockwave(
      position: position.clone(),
      color: const Color(0xFFFF8C00),
      maxRadius: blastRadius,
      duration: 0.4,
    ));

    parent?.add(ImpactSparks(
      position: position.clone(),
      color: const Color(0xFFFFAA00),
      count: 16,
    ));

    game.applyGrenadeBlast(position, blastRadius, blastDamage);
    game.shakeCamera(strength: 8, duration: 0.25);
    game.sfx.playGrenadeExplosion();

    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_exploded) return;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(_rotation);

    final progress = _age / fuseTime;
    final blinkRate = progress > 0.7 ? ((progress - 0.7) / 0.3 * 8) : 0.0;
    final isRed = blinkRate > 0 && (_age * blinkRate) % 1.0 > 0.5;

    canvas.drawCircle(
      Offset.zero,
      5,
      Paint()..color = isRed ? const Color(0xFFFF2200) : const Color(0xFF44DD44),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-1, -7, 2, 4),
      Paint()..color = const Color(0xFFCCCC00),
    );

    canvas.restore();
  }
}
