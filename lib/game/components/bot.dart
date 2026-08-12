import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'projectile.dart';
import 'confetti_explosion.dart';
import 'spawn_effect.dart';
import 'impact_sparks.dart';
import 'shockwave.dart';
import 'floating_text.dart';
import 'power_up.dart';
import 'player.dart';
import '../spark_arena_game.dart';

enum BotType { normal, sniper, elite }

/// Bot ennemi amélioré — IA avec separation steering, flanking, types sniper/élite.
class Bot extends PositionComponent
    with CollisionCallbacks, HasGameReference<SparkArenaGame> {
  final double moveSpeedOverride;
  final double shootCooldownOverride;
  final int maxHeartsOverride;
  final bool isBoss;
  final BotType botType;

  static const double preferredDistance = 130;
  static const double knockbackFriction = 8;
  static const double separationRadius = 50;

  late int hearts;
  // Bouclier élite (absorbe 2 coups)
  int eliteShieldHp = 0;

  double _shootTimer = 0;
  double _chargeCooldown = 0; // boss charge
  final Random _rnd = Random();
  Vector2 knockbackVelocity = Vector2.zero();
  double _spawnInvincibility = 0.8;
  double _flankAngle = 0;
  double _flankAngleTimer = 0;

  late RectangleComponent _body;
  CircleComponent? _eliteShieldVisual;

  static Color _colorForType(bool isBoss, BotType type) {
    if (isBoss) return const Color(0xFFFF0055);
    switch (type) {
      case BotType.sniper: return const Color(0xFFAA44FF);
      case BotType.elite: return const Color(0xFF00CCFF);
      case BotType.normal: return const Color(0xFFFF6B6B);
    }
  }

  Bot({
    required Vector2 position,
    this.moveSpeedOverride = 130,
    this.shootCooldownOverride = 0.75,
    this.maxHeartsOverride = 3,
    this.isBoss = false,
    this.botType = BotType.normal,
  }) : super(
          position: position,
          size: isBoss ? Vector2.all(52) : (botType == BotType.elite ? Vector2.all(38) : Vector2.all(34)),
          anchor: Anchor.center,
        ) {
    hearts = maxHeartsOverride;
    _shootTimer = _rnd.nextDouble() * shootCooldownOverride;
    _flankAngle = _rnd.nextDouble() * 2 * pi;

    // Élite shield
    if (botType == BotType.elite) eliteShieldHp = 2;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final col = _colorForType(isBoss, botType);
    _body = RectangleComponent(
      size: size,
      paint: Paint()..color = col,
      anchor: Anchor.topLeft,
    );
    add(_body);
    add(RectangleHitbox()..collisionType = CollisionType.active);

    parent?.add(SpawnEffect(position: position.clone(), color: col));

    if (botType == BotType.elite) _addEliteShieldVisual();
  }

  void _addEliteShieldVisual() {
    _eliteShieldVisual?.removeFromParent();
    _eliteShieldVisual = CircleComponent(
      radius: size.x / 2 + 8,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()..color = const Color(0xFF00CCFF).withValues(alpha: 0.35),
    );
    add(_eliteShieldVisual!);
  }

  void takeHit({int damage = 1}) {
    if (_spawnInvincibility > 0) return;

    // Bouclier élite absorbe
    if (eliteShieldHp > 0) {
      eliteShieldHp -= damage;
      _body.paint.color = const Color(0xFF00CCFF);
      game.sfx.playEliteShieldBreak();
      Future.delayed(const Duration(milliseconds: 120), () {
        if (isMounted) _body.paint.color = _colorForType(isBoss, botType);
      });
      if (eliteShieldHp <= 0) {
        _eliteShieldVisual?.removeFromParent();
        _eliteShieldVisual = null;
        parent?.add(Shockwave(
          position: position.clone(),
          color: const Color(0xFF00CCFF),
          maxRadius: 40,
          duration: 0.25,
        ));
      }
      return;
    }

    hearts -= damage;
    _body.paint.color = Colors.white;
    game.sfx.playHit();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (isMounted) _body.paint.color = _colorForType(isBoss, botType);
    });

    if (hearts <= 0) {
      _die();
    }
  }

  void _die() {
    parent?.add(ConfettiExplosion(position: position.clone()));
    parent?.add(Shockwave(
      position: position.clone(),
      color: isBoss ? const Color(0xFFFF0055) : const Color(0xFFFF6B6B),
      maxRadius: isBoss ? 100 : 60,
      duration: isBoss ? 0.5 : 0.3,
    ));
    parent?.add(ImpactSparks(
      position: position.clone(),
      color: _colorForType(isBoss, botType),
      count: isBoss ? 16 : 8,
    ));

    game.shakeCamera(strength: isBoss ? 12 : 5, duration: isBoss ? 0.35 : 0.14);
    game.sfx.playBotExplosion(isBoss: isBoss);

    // Score flottant
    final pts = isBoss ? 500 : (botType == BotType.elite ? 150 : (botType == BotType.sniper ? 120 : 100));
    parent?.add(FloatingText(
      text: '+$pts',
      position: position.clone() - Vector2(0, 20),
      color: isBoss ? const Color(0xFFFFD700) : const Color(0xFF41FF99),
      fontSize: isBoss ? 24 : 16,
    ));

    // Lucky Drop — 15% de chance de lâcher un power-up
    if (_rnd.nextDouble() < 0.15) {
      const types = PowerUpType.values;
      final t = types[_rnd.nextInt(types.length)];
      parent?.add(PowerUp(position: position.clone(), type: t));
      game.sfx.playLuckyDrop();
    }

    game.scoreManager.onKill(position, isBoss: isBoss, botType: botType.name);
    game.waveManager.onBotEliminated();
    removeFromParent();
  }

  void applyKnockback(Vector2 impulse) {
    knockbackVelocity += impulse;
  }

  void takeDamageOverTime(double damage) {
    hearts -= 1;
    _body.paint.color = const Color(0xFFFF4444);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (isMounted) _body.paint.color = _colorForType(isBoss, botType);
    });
    if (hearts <= 0) {
      _die();
    }
  }

  Player? _findPlayer() {
    final candidates = parent?.children.query<Player>();
    if (candidates == null || candidates.isEmpty) return null;
    return candidates.first;
  }

  /// Separation steering — évite d'être empilé avec d'autres bots.
  Vector2 _computeSeparation() {
    final sep = Vector2.zero();
    final sibling = parent?.children.query<Bot>() ?? [];
    for (final other in sibling) {
      if (other == this) continue;
      final diff = position - other.position;
      final dist = diff.length;
      if (dist < separationRadius && dist > 0.01) {
        sep.add(diff.normalized() * (separationRadius - dist) / separationRadius);
      }
    }
    return sep;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_spawnInvincibility > 0) _spawnInvincibility -= dt;

    final player = _findPlayer();
    if (player == null) return;

    final toPlayer = player.position - position;
    final distance = toPlayer.length;

    // --- IA de déplacement ---
    final inSafeZone = game.shrinkingZone.isInSafeZone(position);
    Vector2 desiredVel = Vector2.zero();

    if (!inSafeZone) {
      // Retour dans la zone en priorité
      final safeCenter = Vector2(
        game.shrinkingZone.safeRect.center.dx,
        game.shrinkingZone.safeRect.center.dy,
      );
      desiredVel = (safeCenter - position).normalized() * moveSpeedOverride * 1.4;
    } else if (isBoss && hearts <= maxHeartsOverride ~/ 2) {
      // Boss charge le joueur en mode rage
      _chargeCooldown -= dt;
      if (_chargeCooldown <= 0 && distance > 40) {
        _chargeCooldown = 2.5;
        applyKnockback(toPlayer.normalized() * 600);
        game.sfx.playDash();
      }
      desiredVel = toPlayer.normalized() * moveSpeedOverride * 1.6;
    } else if (botType == BotType.sniper) {
      // Sniper : maintient distance max, tire précisément
      const double sniperIdealDist = preferredDistance * 1.8;
      if (distance < sniperIdealDist * 0.8) {
        desiredVel = -toPlayer.normalized() * moveSpeedOverride * 0.8;
      } else if (distance > sniperIdealDist * 1.2) {
        desiredVel = toPlayer.normalized() * moveSpeedOverride * 0.6;
      }
      // Strafing latéral
      final perp = Vector2(-toPlayer.y, toPlayer.x).normalized();
      desiredVel += perp * sin(_flankAngle) * moveSpeedOverride * 0.5;
    } else {
      // Normal/Élite : flanking
      _flankAngleTimer -= dt;
      if (_flankAngleTimer <= 0) {
        _flankAngle = _rnd.nextDouble() * 2 * pi;
        _flankAngleTimer = 1.5 + _rnd.nextDouble() * 1.0;
      }

      if (distance > preferredDistance) {
        // Approche avec déviation angulaire (flanking)
        final perpDir = Vector2(-toPlayer.y, toPlayer.x).normalized();
        final flankOffset = perpDir * sin(_flankAngle) * 0.4;
        desiredVel = (toPlayer.normalized() + flankOffset).normalized() * moveSpeedOverride;
      } else if (distance < preferredDistance * 0.6) {
        desiredVel = -toPlayer.normalized() * moveSpeedOverride * 0.7;
      }
    }

    // Separation
    final sep = _computeSeparation();
    desiredVel += sep * moveSpeedOverride * 0.8;

    if (desiredVel.length2 > 0.01) {
      position += desiredVel.normalized() * desiredVel.length.clamp(0, moveSpeedOverride * 1.6) * dt;
    }

    // Knockback
    if (knockbackVelocity.length2 > 1) {
      position += knockbackVelocity * dt;
      knockbackVelocity *= (1 - knockbackFriction * dt).clamp(0.0, 1.0);
    } else {
      knockbackVelocity = Vector2.zero();
    }

    // Clamp dans l'arène
    final arenaSize = game.size;
    position.x = position.x.clamp(size.x / 2, arenaSize.x - size.x / 2);
    position.y = position.y.clamp(size.y / 2, arenaSize.y - size.y / 2);

    // --- Tir ---
    _shootTimer -= dt;
    final shootRange = botType == BotType.sniper
        ? preferredDistance * 3.5
        : preferredDistance * 2.2;

    if (_shootTimer <= 0 && distance < shootRange) {
      _shootTimer = shootCooldownOverride;
      final dir = toPlayer.normalized();
      final spawnPos = position + dir * (size.x / 2 + 8);

      parent?.add(Projectile(position: spawnPos, direction: dir, fromPlayer: false));

      if (isBoss) {
        // Boss tire en rafale de 3
        for (final perp in [
          Vector2(-dir.y, dir.x) * 14,
          Vector2(dir.y, -dir.x) * 14,
        ]) {
          parent?.add(Projectile(position: spawnPos + perp, direction: dir, fromPlayer: false));
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Barre de vie
    final barW = size.x;
    const barH = 4.0;
    const barY = -10.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, barY, barW, barH), const Radius.circular(2)),
      Paint()..color = Colors.black54,
    );

    final hpFraction = (hearts / maxHeartsOverride).clamp(0.0, 1.0);
    final hpColor = isBoss
        ? const Color(0xFFFF0055)
        : (botType == BotType.elite
            ? const Color(0xFF00CCFF)
            : (botType == BotType.sniper ? const Color(0xFFAA44FF) : const Color(0xFFFF4444)));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, barY, barW * hpFraction, barH),
        const Radius.circular(2),
      ),
      Paint()..color = hpColor,
    );

    // Badge type
    if (isBoss) {
      final tp = TextPainter(
        text: const TextSpan(text: '👑', style: TextStyle(fontSize: 12)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.x / 2 - 6, -22));
    } else if (botType == BotType.sniper) {
      final tp = TextPainter(
        text: const TextSpan(text: '🎯', style: TextStyle(fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.x / 2 - 5, -20));
    }
  }
}
