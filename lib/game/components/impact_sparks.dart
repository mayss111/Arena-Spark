import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Particules d'étincelles au point d'impact d'un projectile.
class ImpactSparks extends Component {
  final Vector2 position;
  final Color color;
  final int count;
  final List<_Spark> _sparks = [];
  final Random _rnd = Random();
  bool _initialized = false;

  ImpactSparks({
    required this.position,
    this.color = const Color(0xFFFFAA00),
    this.count = 6,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (int i = 0; i < count; i++) {
      final angle = _rnd.nextDouble() * 2 * pi;
      final speed = 80 + _rnd.nextDouble() * 160;
      _sparks.add(_Spark(
        pos: position.clone(),
        velocity: Vector2(cos(angle), sin(angle)) * speed,
        color: color,
        life: 0.15 + _rnd.nextDouble() * 0.2,
        size: 2.0 + _rnd.nextDouble() * 3.0,
      ));
    }
    _initialized = true;
  }

  @override
  void update(double dt) {
    if (!_initialized) return;
    bool anyAlive = false;
    for (final spark in _sparks) {
      spark.pos += spark.velocity * dt;
      spark.velocity *= (1 - 8 * dt).clamp(0.0, 1.0);
      spark.age += dt;
      if (spark.age < spark.life) anyAlive = true;
    }
    if (!anyAlive) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (!_initialized) return;
    for (final spark in _sparks) {
      if (spark.age >= spark.life) continue;
      final alpha = (1 - spark.age / spark.life).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = spark.color.withValues(alpha: alpha)
        ..strokeWidth = spark.size
        ..strokeCap = StrokeCap.round;

      final pos = spark.pos;
      final tail = pos - spark.velocity * 0.015;
      canvas.drawLine(
        Offset(tail.x, tail.y),
        Offset(pos.x, pos.y),
        paint,
      );
    }
  }
}

class _Spark {
  Vector2 pos;
  Vector2 velocity;
  Color color;
  double life;
  double size;
  double age = 0;

  _Spark({
    required this.pos,
    required this.velocity,
    required this.color,
    required this.life,
    required this.size,
  });
}
