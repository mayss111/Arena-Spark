import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Traînée de particules pendant le dash du joueur.
class DashTrail extends Component {
  final Vector2 position;
  final Color color;
  final Vector2 velocity;

  final List<_Particle> _particles = [];
  final Random _rnd = Random();
  double _spawnTimer = 0;
  bool _dead = false;
  double _life = 0;
  static const double _maxLife = 0.2;
  static const double _spawnRate = 0.015;

  DashTrail({
    required this.position,
    required this.velocity,
    this.color = const Color(0xFFBFF6FF),
  });

  @override
  void update(double dt) {
    _life += dt;
    if (_life > _maxLife) _dead = true;

    if (!_dead) {
      _spawnTimer -= dt;
      if (_spawnTimer <= 0) {
        _spawnTimer = _spawnRate;
        for (int i = 0; i < 3; i++) {
          final spread = Vector2(
            (_rnd.nextDouble() - 0.5) * 20,
            (_rnd.nextDouble() - 0.5) * 20,
          );
          _particles.add(_Particle(
            pos: position.clone() + spread,
            vel: -velocity * 0.15 + spread * 0.5,
            color: color,
            maxLife: 0.18 + _rnd.nextDouble() * 0.12,
            size: 4 + _rnd.nextDouble() * 5,
          ));
        }
      }
    }

    _particles.removeWhere((p) {
      p.pos += p.vel * dt;
      p.age += dt;
      return p.age > p.maxLife;
    });

    if (_dead && _particles.isEmpty) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (final p in _particles) {
      final alpha = (1 - p.age / p.maxLife).clamp(0.0, 1.0);
      final size = p.size * alpha;
      canvas.drawCircle(
        Offset(p.pos.x, p.pos.y),
        size,
        Paint()..color = p.color.withValues(alpha: alpha * 0.7),
      );
    }
  }
}

class _Particle {
  Vector2 pos;
  Vector2 vel;
  Color color;
  double maxLife;
  double size;
  double age = 0;

  _Particle({
    required this.pos,
    required this.vel,
    required this.color,
    required this.maxLife,
    required this.size,
  });
}
