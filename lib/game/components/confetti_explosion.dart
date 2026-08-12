import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// Explosion de confettis festive (36 particules, étoiles + cercles).
/// Appelée quand un bot OU le joueur est éliminé — toujours rigolo, jamais violent.
class ConfettiExplosion extends ParticleSystemComponent {
  ConfettiExplosion({required Vector2 position})
      : super(
          position: position,
          particle: Particle.generate(
            count: 36,
            lifespan: 1.0,
            generator: (i) {
              final rnd = Random();
              final angle = rnd.nextDouble() * 2 * pi;
              final speed = 90 + rnd.nextDouble() * 160;
              const colors = [
                Colors.pinkAccent,
                Colors.amber,
                Colors.lightBlueAccent,
                Colors.greenAccent,
                Colors.purpleAccent,
                Colors.white,
                Colors.orangeAccent,
              ];
              final radius = 2.5 + rnd.nextDouble() * 4.0;
              return AcceleratedParticle(
                acceleration: Vector2(0, 240),
                speed: Vector2(cos(angle), sin(angle)) * speed,
                child: CircleParticle(
                  radius: radius,
                  paint: Paint()..color = colors[rnd.nextInt(colors.length)],
                ),
              );
            },
          ),
        );
}
