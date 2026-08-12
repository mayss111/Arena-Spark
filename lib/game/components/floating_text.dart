import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Texte flottant de combo/score qui monte et disparaît.
class FloatingText extends Component {
  final String text;
  final Vector2 position;
  final Color color;
  final double fontSize;

  double _age = 0;
  static const double _duration = 0.9;
  late Vector2 _pos;
  late TextPainter _painter;

  FloatingText({
    required this.text,
    required this.position,
    this.color = const Color(0xFFFFD700),
    this.fontSize = 20,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _pos = position.clone();
    _painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    _age += dt;
    // Flotte vers le haut
    _pos.y -= 60 * dt;
    if (_age >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = (_age / _duration).clamp(0.0, 1.0);
    // Apparaît vite, disparaît lentement en fin
    final alpha = progress < 0.3
        ? progress / 0.3
        : (1 - (progress - 0.3) / 0.7).clamp(0.0, 1.0);

    // Scale up puis normal
    final scale = progress < 0.2 ? (1.0 + (0.2 - progress) / 0.2 * 0.5) : 1.0;

    canvas.save();
    canvas.translate(_pos.x - _painter.width / 2, _pos.y);
    canvas.scale(scale, scale);
    canvas.translate(-_painter.width * (scale - 1) / 2, 0);

    // Re-peindre avec alpha
    final paint = Paint()..color = Colors.transparent;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, _painter.width, _painter.height),
      paint,
    );

    // Dessine le texte avec opacité
    _painter.text = TextSpan(
      text: text,
      style: TextStyle(
        color: color.withValues(alpha: alpha),
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: alpha * 0.8),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
    _painter.layout();
    _painter.paint(canvas, Offset.zero);
    canvas.restore();
  }
}
