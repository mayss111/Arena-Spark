import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Bannière d'annonce d'action / killstreaks (DNA Free Fire).
/// Affiche "PREMIER SANG", "DOUBLE ÉLIMINATION", "VICTOIRE ROYALE !", etc.
class KillAnnouncer extends PositionComponent with HasGameReference {
  final String title;
  final String subtitle;
  final Color color;
  double _age = 0;
  static const double duration = 2.2;

  KillAnnouncer({
    required this.title,
    this.subtitle = '',
    this.color = const Color(0xFFFFD700),
  }) : super(anchor: Anchor.topCenter);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(game.size.x / 2, 80);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    double opacity;
    if (_age < 0.2) {
      opacity = _age / 0.2;
    } else if (_age > duration - 0.4) {
      opacity = (duration - _age) / 0.4;
    } else {
      opacity = 1.0;
    }
    opacity = opacity.clamp(0.0, 1.0);

    final textPainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: color.withValues(alpha: opacity),
          fontSize: 26,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
          shadows: [
            Shadow(
              color: color.withValues(alpha: opacity * 0.7),
              blurRadius: 16,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.6 * opacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: textPainter.width + 40,
          height: textPainter.height + 16,
        ),
        const Radius.circular(10),
      ),
      bgPaint,
    );

    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }
}
