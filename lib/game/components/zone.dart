import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Zone de sécurité qui rétrécit au fil du temps.
/// Tout joueur/bot en dehors subit des dégâts passifs.
/// Rendu visuel : bord rouge translucide animé (mur d'énergie).
class ShrinkingZone extends PositionComponent with HasGameReference {
  /// Temps (en secondes) avant que la zone commence à rétrécir.
  final double delayBeforeShrink;

  /// Vitesse de rétrécissement en pixels/seconde de chaque côté.
  final double shrinkSpeed;

  /// Taille minimale de la zone (rayon intérieur min).
  final double minSizeFraction;

  /// Dégâts par seconde infligés aux entités hors zone.
  final double damagePerSecond;

  /// Fraction actuelle de la zone (1.0 = plein écran, 0.0 = zone fermée).
  double zoneFraction = 1.0;

  double _elapsed = 0;
  double _pulseTimer = 0;
  bool _active = false;

  /// Rectangle courant de la zone safe (en coords monde).
  Rect get safeRect {
    final arenaSize = game.size;
    final marginX = arenaSize.x * (1 - zoneFraction) / 2;
    final marginY = arenaSize.y * (1 - zoneFraction) / 2;
    return Rect.fromLTRB(marginX, marginY, arenaSize.x - marginX, arenaSize.y - marginY);
  }

  /// Vérifie si une position est dans la zone safe.
  bool isInSafeZone(Vector2 pos) => safeRect.contains(pos.toOffset());

  ShrinkingZone({
    this.delayBeforeShrink = 15.0,
    this.shrinkSpeed = 0.012, // fraction/seconde
    this.minSizeFraction = 0.15,
    this.damagePerSecond = 0.5,
  });

  /// Démarre le timer de rétrécissement (appelé par WaveManager).
  void activate() {
    _active = true;
    _elapsed = 0;
  }

  /// Remet la zone à 100%.
  void reset() {
    zoneFraction = 1.0;
    _elapsed = 0;
    _active = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt;

    if (!_active) return;
    _elapsed += dt;

    if (_elapsed > delayBeforeShrink && zoneFraction > minSizeFraction) {
      zoneFraction = (zoneFraction - shrinkSpeed * dt).clamp(minSizeFraction, 1.0);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (zoneFraction >= 0.999) return; // zone pleine, rien à dessiner

    final arenaSize = game.size;
    final safe = safeRect;
    final pulse = (sin(_pulseTimer * 3) * 0.15 + 0.85).clamp(0.0, 1.0);

    // Zone dangereuse : 4 rectangles autour de la safe zone.
    final dangerPaint = Paint()
      ..color = Color.fromRGBO(255, 50, 50, 0.18 * pulse);

    // Haut
    canvas.drawRect(
      Rect.fromLTRB(0, 0, arenaSize.x, safe.top),
      dangerPaint,
    );
    // Bas
    canvas.drawRect(
      Rect.fromLTRB(0, safe.bottom, arenaSize.x, arenaSize.y),
      dangerPaint,
    );
    // Gauche
    canvas.drawRect(
      Rect.fromLTRB(0, safe.top, safe.left, safe.bottom),
      dangerPaint,
    );
    // Droite
    canvas.drawRect(
      Rect.fromLTRB(safe.right, safe.top, arenaSize.x, safe.bottom),
      dangerPaint,
    );

    // Bord de la zone : ligne d'énergie animée.
    final borderPaint = Paint()
      ..color = Color.fromRGBO(255, 80, 80, 0.6 * pulse)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(safe, borderPaint);

    // Glow intérieur du bord.
    final glowPaint = Paint()
      ..color = Color.fromRGBO(255, 60, 60, 0.12 * pulse)
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRect(safe.deflate(6), glowPaint);
  }
}
