import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/sfx_engine.dart';
import 'components/weapon.dart';
import 'components/player.dart';
import 'components/bot.dart';
import 'components/projectile.dart';
import 'components/hud.dart';
import 'components/ambient_background.dart';
import 'components/zone.dart';
import 'components/power_up.dart';
import 'components/obstacle.dart';
import 'components/air_drop.dart';
import 'components/minimap.dart';
import 'components/kill_announcer.dart';
import 'components/impact_sparks.dart';
import 'components/loot_item.dart';
import 'components/floating_text.dart';
import 'wave_manager.dart';
import 'score_manager.dart';
import 'data/game_storage.dart';

class SparkArenaGame extends FlameGame
    with HasCollisionDetection, DragCallbacks, TapCallbacks, KeyboardEvents {

  late final SfxEngine sfx;

  late Player player;
  late Hud hud;
  late MiniMapHud miniMap;
  late JoystickComponent joystick;
  late ShrinkingZone shrinkingZone;
  late WaveManager waveManager;
  late ScoreManager scoreManager;
  late GameStorage storage;

  bool playerWon = false;
  bool _gameEnded = false;
  bool soundEnabled = true;

  double _shakeTimer = 0;
  double _shakeStrength = 0;
  Vector2 _shakeOffset = Vector2.zero();

  double _powerUpSpawnTimer = 0;
  double _lootSpawnTimer = 0;
  static const double _powerUpSpawnInterval = 12.0;
  static const double _lootSpawnInterval = 8.0;
  static const int _initialLootCount = 18;

  double survivalTime = 0;

  final Random _rnd = Random();

  void Function(bool won, int score, int wave, double survTime)? onGameEnd;

  void shakeCamera({double strength = 4, double duration = 0.12}) {
    _shakeStrength = max(_shakeStrength, strength);
    _shakeTimer = duration;
  }

  void showWaveAnnouncement(int wave) {
    add(KillAnnouncer(
      title: 'VAGUE $wave',
      subtitle: wave == 8
          ? '⚡ VAGUE ÉLITE !'
          : (wave >= 7 ? '🎯 Snipers détectés !' : (wave >= 3 ? '⚠ La zone rétrécit !' : 'Préparez-vous !')),
      color: wave == 8
          ? const Color(0xFF00CCFF)
          : (wave >= 5 ? const Color(0xFFFF4444) : const Color(0xFF41E0FF)),
    ));
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    storage = await GameStorage.getInstance();
    camera.viewfinder.anchor = Anchor.topLeft;

    sfx = SfxEngine();
    sfx.enabled = storage.sfxVolume > 0;
    sfx.volume = storage.sfxVolume;

    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF16213E),
    ));
    add(AmbientBackground(size: size.clone()));

    _spawnObstacles();

    shrinkingZone = ShrinkingZone();
    add(shrinkingZone);

    scoreManager = ScoreManager();
    add(scoreManager);

    waveManager = WaveManager();
    add(waveManager);

    _spawnPlayer();
    _setupJoystick();
    _setupActionButtons();

    _spawnInitialLoot();

    hud = Hud(
      hearts: player.hearts,
      botsRemaining: 0,
      waveNumber: 1,
    );
    add(hud);

    miniMap = MiniMapHud();
    add(miniMap);

    waveManager.start();
    _powerUpSpawnTimer = 8.0;
    _lootSpawnTimer = _lootSpawnInterval;
  }

  void _spawnInitialLoot() {
    for (int i = 0; i < _initialLootCount; i++) {
      _spawnRandomLoot(awayFromCenter: i < 12);
    }
  }

  void _spawnRandomLoot({bool awayFromCenter = false}) {
    final safe = shrinkingZone.safeRect;
    double x, y;
    if (awayFromCenter) {
      final edge = _rnd.nextInt(4);
      switch (edge) {
        case 0:
          x = safe.left + safe.width * (0.1 + _rnd.nextDouble() * 0.8);
          y = safe.top + safe.height * (0.05 + _rnd.nextDouble() * 0.2);
          break;
        case 1:
          x = safe.left + safe.width * (0.1 + _rnd.nextDouble() * 0.8);
          y = safe.bottom - safe.height * (0.05 + _rnd.nextDouble() * 0.2);
          break;
        case 2:
          x = safe.left + safe.width * (0.05 + _rnd.nextDouble() * 0.2);
          y = safe.top + safe.height * (0.1 + _rnd.nextDouble() * 0.8);
          break;
        default:
          x = safe.right - safe.width * (0.05 + _rnd.nextDouble() * 0.2);
          y = safe.top + safe.height * (0.1 + _rnd.nextDouble() * 0.8);
          break;
      }
    } else {
      x = safe.left + 30 + _rnd.nextDouble() * (safe.width - 60);
      y = safe.top + 30 + _rnd.nextDouble() * (safe.height - 60);
    }

    final lootRoll = _rnd.nextDouble();
    LootItem item;
    if (lootRoll < 0.4) {
      final weapons = [WeaponType.smg, WeaponType.ar, WeaponType.shotgun];
      final rarerRoll = _rnd.nextDouble();
      final wpn = rarerRoll < 0.08
          ? WeaponType.sniper
          : (rarerRoll < 0.15 ? WeaponType.rocket : weapons[_rnd.nextInt(weapons.length)]);
      item = LootItem(
        position: Vector2(x, y),
        lootType: LootType.weapon,
        weaponType: wpn,
      );
    } else if (lootRoll < 0.6) {
      item = LootItem(
        position: Vector2(x, y),
        lootType: LootType.heal,
        healAmount: 2,
      );
    } else if (lootRoll < 0.75) {
      item = LootItem(
        position: Vector2(x, y),
        lootType: LootType.shield,
      );
    } else if (lootRoll < 0.88) {
      item = LootItem(
        position: Vector2(x, y),
        lootType: LootType.ammo,
        ammoAmount: 20,
      );
    } else {
      const pus = PowerUpType.values;
      item = LootItem(
        position: Vector2(x, y),
        lootType: LootType.powerUp,
        powerUpType: pus[_rnd.nextInt(pus.length)],
      );
    }
    add(item);
  }

  void _spawnObstacles() {
    add(Obstacle(position: Vector2(size.x * 0.3, size.y * 0.35), type: ObstacleType.energyBarrier));
    add(Obstacle(position: Vector2(size.x * 0.7, size.y * 0.35), type: ObstacleType.energyBarrier));
    add(Obstacle(position: Vector2(size.x * 0.3, size.y * 0.65), type: ObstacleType.energyBarrier));
    add(Obstacle(position: Vector2(size.x * 0.7, size.y * 0.65), type: ObstacleType.energyBarrier));
    add(Obstacle(position: Vector2(size.x * 0.15, size.y * 0.5), type: ObstacleType.energyBarrier));
    add(Obstacle(position: Vector2(size.x * 0.85, size.y * 0.5), type: ObstacleType.energyBarrier));
    add(Obstacle(position: Vector2(size.x * 0.5, size.y * 0.15), type: ObstacleType.energyBarrier));
    add(Obstacle(position: Vector2(size.x * 0.5, size.y * 0.85), type: ObstacleType.energyBarrier));

    add(Obstacle(position: Vector2(size.x * 0.5, size.y * 0.25), type: ObstacleType.bouncePad));
    add(Obstacle(position: Vector2(size.x * 0.5, size.y * 0.75), type: ObstacleType.bouncePad));
    add(Obstacle(position: Vector2(size.x * 0.25, size.y * 0.5), type: ObstacleType.bouncePad));
    add(Obstacle(position: Vector2(size.x * 0.75, size.y * 0.5), type: ObstacleType.bouncePad));
  }

  void _spawnPlayer() {
    player = Player(
      position: size / 2,
      skinId: storage.selectedSkin,
    );
    add(player);
  }

  void _setupJoystick() {
    final knob = CircleComponent(
      radius: 22,
      paint: Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    final background = CircleComponent(
      radius: 55,
      paint: Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    joystick = JoystickComponent(
      knob: knob,
      background: background,
      margin: const EdgeInsets.only(left: 44, bottom: 44),
    );
    add(joystick);
  }

  void _setupActionButtons() {
    add(_CircleHudButton(
      label: '🔫',
      color: const Color(0xFF41E0FF),
      onPressed: () => player.shoot(),
      position: Vector2(size.x - 80, size.y - 90),
      cooldownGetter: () => player.shootCooldownFraction,
      reloadGetter: () => player.reloadFraction,
    ));

    add(_CircleHudButton(
      label: '🔨',
      color: const Color(0xFFFFD166),
      onPressed: () => player.meleeAttack(),
      position: Vector2(size.x - 160, size.y - 100),
      cooldownGetter: () => player.meleeCooldownFraction,
    ));

    add(_CircleHudButton(
      label: '💨',
      color: const Color(0xFFBFF6FF),
      onPressed: () => player.dash(),
      position: Vector2(size.x - 230, size.y - 54),
      cooldownGetter: () => player.dashCooldownFraction,
    ));

    add(_CircleHudButton(
      label: '💣',
      color: const Color(0xFFFF8C00),
      onPressed: () => player.throwGrenade(),
      position: Vector2(size.x - 80, size.y - 170),
      cooldownGetter: () => player.grenadeCooldownFraction,
    ));

    add(_CircleHudButton(
      label: '🔄',
      color: const Color(0xFF4CAF50),
      onPressed: () => player.reload(),
      position: Vector2(size.x - 160, size.y - 180),
      cooldownGetter: () => 0.0,
    ));

    add(_CircleHudButton(
      label: '🔀',
      color: const Color(0xFF9B59B6),
      onPressed: () => player.cycleWeapon(),
      position: Vector2(size.x - 230, size.y - 140),
      cooldownGetter: () => 0.0,
    ));
  }

  void _spawnPowerUp() {
    final safe = shrinkingZone.safeRect;
    final x = safe.left + 30 + _rnd.nextDouble() * (safe.width - 60);
    final y = safe.top + 30 + _rnd.nextDouble() * (safe.height - 60);
    const types = PowerUpType.values;
    final type = types[_rnd.nextInt(types.length)];
    add(PowerUp(position: Vector2(x, y), type: type));
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;

    double dx = 0, dy = 0;
    if (keysPressed.contains(LogicalKeyboardKey.keyW) || keysPressed.contains(LogicalKeyboardKey.arrowUp)) dy -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyS) || keysPressed.contains(LogicalKeyboardKey.arrowDown)) dy += 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft)) dx -= 1;
    if (keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight)) dx += 1;

    player.keyboardInput = Vector2(dx, dy);

    if (isDown) {
      if (keysPressed.contains(LogicalKeyboardKey.space)) player.shoot();
      if (keysPressed.contains(LogicalKeyboardKey.shiftLeft) || keysPressed.contains(LogicalKeyboardKey.shiftRight)) player.dash();
      if (keysPressed.contains(LogicalKeyboardKey.keyE)) player.meleeAttack();
      if (keysPressed.contains(LogicalKeyboardKey.keyG)) player.throwGrenade();
      if (keysPressed.contains(LogicalKeyboardKey.keyR)) player.reload();
      if (keysPressed.contains(LogicalKeyboardKey.digit1)) player.switchToSlot(0);
      if (keysPressed.contains(LogicalKeyboardKey.digit2)) player.switchToSlot(1);
      if (keysPressed.contains(LogicalKeyboardKey.keyQ)) player.cycleWeapon();
    }

    return KeyEventResult.handled;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_gameEnded) return;

    survivalTime += dt;

    if (!joystick.delta.isZero()) {
      player.moveInput = joystick.relativeDelta;
    } else {
      player.moveInput = Vector2.zero();
    }

    if (player.isMounted) {
      hud.updateHearts(player.hearts);
      hud.updatePowerUps(
        shield: player.shieldTimeRemaining,
        doubleFire: player.doubleFireTimeRemaining,
        speed: player.speedTimeRemaining,
        damage: player.damageTimeRemaining,
      );
      hud.updateSurvivalTime(survivalTime);
      hud.updateRageMode(player.isRageMode);
      hud.updateWeaponInfo(
        player.currentWeapon,
        player.currentAmmoInMag,
        player.currentAmmoReserve,
        player.weaponSlots,
      );
    } else {
      hud.updateHearts(0);
    }
    hud.updateBots(children.query<Bot>().length);
    hud.updateWave(waveManager.currentWave);
    hud.updateScore(scoreManager.score);
    hud.updateCombo(scoreManager.combo);

    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
      _shakeOffset = Vector2(
        (_rnd.nextDouble() * 2 - 1) * _shakeStrength,
        (_rnd.nextDouble() * 2 - 1) * _shakeStrength,
      );
      camera.viewfinder.position = _shakeOffset;
    } else if (!_shakeOffset.isZero()) {
      _shakeOffset = Vector2.zero();
      _shakeStrength = 0;
      camera.viewfinder.position = Vector2.zero();
    }

    _powerUpSpawnTimer -= dt;
    if (_powerUpSpawnTimer <= 0) {
      _powerUpSpawnTimer = _powerUpSpawnInterval + _rnd.nextDouble() * 6;
      _spawnPowerUp();
    }

    _lootSpawnTimer -= dt;
    final lootCount = children.query<LootItem>().length;
    if (_lootSpawnTimer <= 0 && lootCount < _initialLootCount + 12) {
      _lootSpawnTimer = _lootSpawnInterval + _rnd.nextDouble() * 4;
      _spawnRandomLoot();
    }

    if (player.isMounted) {
      for (final pu in children.query<PowerUp>().toList()) {
        if (!pu.collected && _isColliding(pu, player, expandBy: 8)) {
          player.applyPowerUp(pu.type);
          pu.collect();
        }
      }

      for (final loot in children.query<LootItem>().toList()) {
        if (_isColliding(loot, player, expandBy: 10)) {
          _applyLoot(loot);
          loot.collect();
        }
      }

      for (final ad in children.query<AirDrop>().toList()) {
        if (ad.landed && !ad.opened && _isColliding(ad, player)) {
          ad.open();
        }
      }
    }

    for (final projectile in children.query<Projectile>().toList()) {
      bool hitObstacle = false;
      for (final obs in children.query<Obstacle>().toList()) {
        if (obs.type == ObstacleType.energyBarrier && _isColliding(projectile, obs)) {
          add(ImpactSparks(
            position: projectile.position.clone(),
            color: const Color(0xFF41E0FF),
            count: 4,
          ));
          projectile.removeFromParent();
          hitObstacle = true;
          break;
        }
      }
      if (hitObstacle) continue;

      if (projectile.fromPlayer) {
        for (final bot in children.query<Bot>().toList()) {
          if (_isColliding(projectile, bot)) {
            final dmg = projectile.damage;
            bot.takeHit(damage: dmg);
            bot.applyKnockback(projectile.direction.normalized() * (140 + projectile.speed * 0.04));
            add(ImpactSparks(
              position: projectile.position.clone(),
              color: projectile.color,
              count: projectile.isSniper ? 8 : 5,
            ));
            shakeCamera(strength: projectile.isRocket ? 10 : (projectile.isSniper ? 6 : 3));
            if (projectile.isRocket) {
              applyGrenadeBlast(projectile.position.clone(), 90, dmg);
            }
            projectile.removeFromParent();
            break;
          }
        }
      } else {
        if (player.isMounted && _isColliding(projectile, player)) {
          player.takeHit();
          player.applyKnockback(projectile.direction.normalized() * 160);
          add(ImpactSparks(
            position: projectile.position.clone(),
            color: const Color(0xFFFF4444),
            count: 5,
          ));
          shakeCamera(strength: 3);
          projectile.removeFromParent();
        }
      }
    }

    if (player.isMounted && player.isMeleeActive) {
      for (final bot in children.query<Bot>().toList()) {
        final toBot = bot.position - player.position;
        if (toBot.length <= Player.meleeRange) {
          bot.takeHit(damage: player.meleeDamage);
          bot.applyKnockback(toBot.normalized() * Player.meleeKnockback);
        }
      }
    }

    if (!player.isMounted && !_gameEnded) {
      _endGame(won: false);
    } else if (waveManager.allWavesCompleted && children.query<Bot>().isEmpty && !_gameEnded) {
      _endGame(won: true);
    }
  }

  void _applyLoot(LootItem loot) {
    switch (loot.lootType) {
      case LootType.weapon:
        if (loot.weaponType != null) {
          player.pickupWeapon(loot.weaponType!);
        }
        break;
      case LootType.heal:
        player.heal(loot.healAmount);
        break;
      case LootType.ammo:
        for (final w in player.weaponSlots) {
          player.addAmmo(w, loot.ammoAmount);
        }
        break;
      case LootType.shield:
        player.addShield();
        break;
      case LootType.powerUp:
        if (loot.powerUpType != null) {
          player.applyPowerUp(loot.powerUpType!);
        }
        break;
    }
  }

  bool _isColliding(PositionComponent a, PositionComponent b, {double expandBy = 0}) {
    final ra = a.toRect().inflate(expandBy);
    final rb = b.toRect();
    return ra.overlaps(rb);
  }

  void applyGrenadeBlast(Vector2 center, double radius, int damage) {
    for (final bot in children.query<Bot>().toList()) {
      final dist = (bot.position - center).length;
      if (dist <= radius) {
        bot.takeHit(damage: damage);
        final dir = (bot.position - center).normalized();
        bot.applyKnockback(dir * (350 + (radius - dist) * 1.5));
      }
    }
    if (player.isMounted) {
      final dist = (player.position - center).length;
      if (dist <= radius * 0.6) {
        player.takeHit();
        final dir = (player.position - center).normalized();
        player.applyKnockback(dir * 200);
      }
    }
    add(ImpactSparks(position: center, color: Colors.orange, count: 12));
    shakeCamera(strength: 8, duration: 0.2);
  }

  void _endGame({required bool won}) {
    _gameEnded = true;
    playerWon = won;
    if (won) sfx.playVictory();
    _saveResults();
    onGameEnd?.call(won, scoreManager.score, waveManager.currentWave, survivalTime);
  }

  Future<void> _saveResults() async {
    await storage.setHighScore(scoreManager.score);
    await storage.addToTotalScore(scoreManager.score);
    await storage.setMaxWave(waveManager.currentWave);
  }

  void restart() {
    children.query<Bot>().forEach((b) => b.removeFromParent());
    children.query<Projectile>().forEach((p) => p.removeFromParent());
    children.query<PowerUp>().forEach((pu) => pu.removeFromParent());
    children.query<LootItem>().forEach((l) => l.removeFromParent());
    children.query<AirDrop>().forEach((ad) => ad.removeFromParent());
    children.query<FloatingText>().forEach((f) => f.removeFromParent());
    if (player.isMounted) player.removeFromParent();

    _gameEnded = false;
    playerWon = false;
    _powerUpSpawnTimer = 8.0;
    _lootSpawnTimer = _lootSpawnInterval;
    survivalTime = 0;

    shrinkingZone.reset();
    waveManager.reset();
    scoreManager.reset();

    _spawnPlayer();
    _spawnInitialLoot();
    waveManager.start();
  }

  void pauseGame() {
    pauseEngine();
  }

  void resumeGame() {
    resumeEngine();
  }

  @override
  void onRemove() {
    sfx.dispose();
    super.onRemove();
  }
}

class _CircleHudButton extends PositionComponent
    with TapCallbacks, HasGameReference {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final double Function() cooldownGetter;
  final double Function()? reloadGetter;

  bool _pressed = false;

  _CircleHudButton({
    required this.label,
    required this.color,
    required this.onPressed,
    required Vector2 position,
    required this.cooldownGetter,
    this.reloadGetter,
  }) : super(position: position, size: Vector2.all(60), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleComponent(
      radius: 30,
      paint: Paint()..color = color.withValues(alpha: 0.3),
      anchor: Anchor.center,
      position: size / 2,
    ));
    add(TextComponent(
      text: label,
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(style: const TextStyle(fontSize: 26)),
    ));
  }

  @override
  void onTapDown(TapDownEvent event) {
    _pressed = true;
    onPressed();
  }

  @override
  void onTapUp(TapUpEvent event) {
    _pressed = false;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _pressed = false;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final cd = cooldownGetter().clamp(0.0, 1.0);
    final reload = reloadGetter?.call().clamp(0.0, 1.0) ?? 0.0;
    if (cd > 0.01 || reload > 0.01) {
      final displayCd = max(cd, reload);
      final rect = Rect.fromCircle(center: Offset(size.x / 2, size.y / 2), radius: 30);
      canvas.drawArc(
        rect,
        -pi / 2,
        displayCd * 2 * pi,
        true,
        Paint()..color = Colors.black.withValues(alpha: 0.55),
      );
      canvas.drawArc(
        rect,
        -pi / 2,
        displayCd * 2 * pi,
        false,
        Paint()
          ..color = color.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    if (_pressed) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        32,
        Paint()..color = Colors.white.withValues(alpha: 0.25),
      );
    }
  }
}
