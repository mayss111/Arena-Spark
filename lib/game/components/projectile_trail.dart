import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Traînée lumineuse derrière un projectile.
/// Série de points qui s'estompent progressivement.
class ProjectileTrail extends PositionComponent {
  final Color color;
  final List<_TrailPoint> _points = [];
  static const int maxPoints = 12;

  ProjectileTrail({this.color = const Color(0xFF41E0FF)});

  /// Appelé chaque frame par le projectile parent pour enregistrer la position.
  void recordPosition(Vector2 pos) {
    _points.add(_TrailPoint(position: pos.clone(), age: 0));
    if (_points.length > maxPoints) {
      _points.removeAt(0);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (final point in _points) {
      point.age += dt;
    }
    _points.removeWhere((p) => p.age > 0.3);

    // Auto-remove quand plus de points et que le parent est parti
    if (_points.isEmpty && !isMounted) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (int i = 0; i < _points.length; i++) {
      final point = _points[i];
      final progress = (point.age / 0.3).clamp(0.0, 1.0);
      final opacity = (1.0 - progress) * 0.6;
      final radius = (1.0 - progress) * 5;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(point.position.toOffset(), radius, paint);
    }
  }
}

class _TrailPoint {
  final Vector2 position;
  double age;

  _TrailPoint({required this.position, required this.age});
}
