import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Flash lumineux devant le canon au moment du tir.
class MuzzleFlash extends PositionComponent {
  final Color color;
  double _age = 0;
  static const double _duration = 0.07;

  MuzzleFlash({
    required Vector2 position,
    this.color = const Color(0xFFFFFFFF),
  }) : super(position: position, anchor: Anchor.center, size: Vector2.all(20));

  @override
  void update(double dt) {
    _age += dt;
    if (_age >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = (_age / _duration).clamp(0.0, 1.0);
    final alpha = (1 - progress) * 0.9;
    final radius = (1 - progress) * 10 + 2;

    // Glow externe
    canvas.drawCircle(
      Offset.zero,
      radius * 2,
      Paint()
        ..color = color.withValues(alpha: alpha * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Flash central
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()..color = color.withValues(alpha: alpha),
    );
  }
}
