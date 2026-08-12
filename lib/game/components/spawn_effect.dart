import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

class SpawnEffect extends PositionComponent {
  final Color color;
  final bool reverse;
  double _age = 0;
  static const double duration = 0.7;

  SpawnEffect({
    required Vector2 position,
    this.color = const Color(0xFF41E0FF),
    this.reverse = false,
  }) : super(position: position, anchor: Anchor.center);

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
    final rawProgress = (_age / duration).clamp(0.0, 1.0);
    final progress = reverse ? 1.0 - rawProgress : rawProgress;

    if (progress < 0.65) {
      final expandProgress = progress / 0.65;
      final radius = 5 + expandProgress * 50;
      final opacity = (1.0 - expandProgress * 0.5).clamp(0.0, 1.0);

      final ringPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5 - expandProgress * 2;
      canvas.drawCircle(Offset.zero, radius, ringPaint);

      final innerGlow = Paint()
        ..color = color.withValues(alpha: opacity * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(Offset.zero, radius * 0.85, innerGlow);

      for (int i = 0; i < 8; i++) {
        final a = (pi * 2 / 8) * i + expandProgress * pi * 0.5;
        final d = radius * (0.7 + expandProgress * 0.3);
        final dotPaint = Paint()..color = color.withValues(alpha: opacity * 0.9);
        canvas.drawCircle(Offset(cos(a) * d, sin(a) * d), 2.5, dotPaint);
      }
    }

    if (progress >= 0.5) {
      final implodeProgress = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
      final radius = 50 * (1.0 - implodeProgress);
      final opacity = (1.0 - implodeProgress).clamp(0.0, 1.0);

      final flashPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.75)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset.zero, radius * 0.45, flashPaint);

      final centerPaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.85);
      canvas.drawCircle(Offset.zero, radius * 0.22, centerPaint);

      final starPaint = Paint()..color = color.withValues(alpha: opacity * 0.9);
      for (int i = 0; i < 10; i++) {
        final a = (pi * 2 / 10) * i + implodeProgress * pi * 1.2;
        final d = radius * 0.75 * (reverse ? (1.0 - implodeProgress) : implodeProgress);
        canvas.drawCircle(Offset(cos(a) * d, sin(a) * d), 2, starPaint);
      }
    }
  }
}

class EliminationEffect extends ParticleSystemComponent {
  EliminationEffect(
      {required Vector2 position,
      Color color = const Color(0xFFFF6B6B),
      bool teleportStyle = true})
      : super(
          position: position,
          particle: Particle.generate(
            count: teleportStyle ? 48 : 36,
            lifespan: teleportStyle ? 1.2 : 1.0,
            generator: (i) {
              final rnd = Random();
              final angle = rnd.nextDouble() * 2 * pi;
              final speed = teleportStyle
                  ? 80 + rnd.nextDouble() * 180
                  : 100 + rnd.nextDouble() * 150;
              final colors = [
                color,
                color.withValues(alpha: 0.7),
                Colors.white,
                Colors.amber,
                Colors.lightBlueAccent,
                Colors.greenAccent,
                Colors.purpleAccent,
              ];
              final radius = teleportStyle
                  ? (i % 3 == 0 ? 4.0 : 2.5)
                  : 2.0 + rnd.nextDouble() * 4.0;
              final partColor = colors[rnd.nextInt(colors.length)];
              if (teleportStyle && i % 6 == 0) {
                return SpiralParticle(
                  angle: angle,
                  radius: 40 + rnd.nextDouble() * 30,
                  color: color,
                  lifespan: 1.2,
                );
              }
              return AcceleratedParticle(
                acceleration: Vector2(0, teleportStyle ? 100 : 250),
                speed: Vector2(cos(angle), sin(angle)) * speed,
                child: CircleParticle(
                  radius: radius,
                  paint: Paint()..color = partColor,
                ),
              );
            },
          ),
        );
}

class SpiralParticle extends Particle {
  final double angle;
  final double radius;
  final Color color;
  SpiralParticle({
    required this.angle,
    required this.radius,
    required this.color,
    required double lifespan,
  }) : super(lifespan: lifespan);

  @override
  void render(Canvas canvas) {
    final t = progress;
    final a = angle + t * pi * 2;
    final r = radius * (1 - t * 0.5);
    final paint = Paint()
      ..color = color.withValues(alpha: 1 - t)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(Offset(cos(a) * r, sin(a) * r), 3 + t * 2, paint);
  }
}
