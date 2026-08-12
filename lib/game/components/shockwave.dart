import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Onde de choc expansive lors d'une explosion / mort de bot.
class Shockwave extends PositionComponent {
  final Color color;
  final double maxRadius;
  final double duration;

  double _elapsed = 0;
  double _radius = 0;

  Shockwave({
    required Vector2 position,
    this.color = const Color(0xFFFF6B6B),
    this.maxRadius = 60,
    this.duration = 0.35,
  }) : super(position: position, anchor: Anchor.center);

  @override
  void update(double dt) {
    _elapsed += dt;
    final progress = (_elapsed / duration).clamp(0.0, 1.0);
    // ease-out
    _radius = maxRadius * (1 - (1 - progress) * (1 - progress));
    if (_elapsed >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = (_elapsed / duration).clamp(0.0, 1.0);
    final alpha = (1 - progress) * 0.8;
    final strokeWidth = (1 - progress) * 4 + 1;

    final paint = Paint()
      ..color = color.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(Offset.zero, _radius, paint);

    // Second ring légèrement en retard
    if (progress > 0.15) {
      final r2 = _radius * 0.7;
      final a2 = (1 - progress) * 0.4;
      canvas.drawCircle(
        Offset.zero,
        r2,
        Paint()
          ..color = Colors.white.withValues(alpha: a2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 0.5,
      );
    }
  }
}
