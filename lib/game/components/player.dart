import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'projectile.dart';
import 'confetti_explosion.dart';
import 'spawn_effect.dart';
import 'power_up.dart';
import 'weapon.dart';
import 'obstacle.dart';
import 'dash_trail.dart';
import 'muzzle_flash.dart';
import 'shockwave.dart';
import 'grenade.dart';
import 'floating_text.dart';
import '../spark_arena_game.dart';
import '../data/skin_data.dart';

class Player extends PositionComponent
    with CollisionCallbacks, HasGameReference<SparkArenaGame> {
  static const double baseMoveSpeed = 180;
  static const int maxHearts = 5;
  static const double dashCooldown = 1.2;
  static const double dashDuration = 0.18;
  static const double dashSpeedMultiplier = 3.4;
  static const double meleeCooldown = 0.5;
  static const double meleeRange = 50;
  static const double meleeKnockback = 360;
  static const double shotKnockback = 90;
  static const double knockbackFriction = 8;
  static const double grenadeCooldown = 5.0;
  static const int maxSlots = 2;

  int hearts = maxHearts;
  Vector2 aimDirection = Vector2(0, -1);
  Vector2 moveInput = Vector2.zero();
  Vector2 knockbackVelocity = Vector2.zero();

  Vector2 keyboardInput = Vector2.zero();

  double _shootTimer = 0;
  double _dashTimer = 0;
  double _dashActiveTimer = 0;
  double _meleeTimer = 0;
  double _grenadeTimer = 0;
  double _reloadTimer = 0;
  bool get isDashing => _dashActiveTimer > 0;
  bool get isReloading => _reloadTimer > 0;

  WeaponType currentWeapon = WeaponType.pistol;
  int currentSlot = 0;
  final List<WeaponType> weaponSlots = [WeaponType.pistol, WeaponType.pistol];
  final Map<WeaponType, int> ammoInMag = {};
  final Map<WeaponType, int> ammoReserve = {};

  bool hasShield = false;
  double _shieldTimer = 0;
  bool hasDoubleFire = false;
  double _doubleFireTimer = 0;
  bool hasSpeedBoost = false;
  double _speedBoostTimer = 0;
  bool hasDamageBoost = false;
  double _damageBoostTimer = 0;

  bool get isRageMode => hearts <= 1;
  double _ragePulseTimer = 0;
  bool _ragePulseVisible = false;

  double _zoneDamageAccumulator = 0;
  double _stepTimer = 0;

  Color skinColor;
  Color skinSecondaryColor;
  String skinId;

  late final RectangleComponent _body;
  CircleComponent? _shieldVisual;
  double _dashTrailTimer = 0;

  Player({
    required Vector2 position,
    this.skinId = 'eclair',
  })  : skinColor = getSkinById(skinId).primaryColor,
        skinSecondaryColor = getSkinById(skinId).secondaryColor,
        super(
          position: position,
          size: Vector2.all(36),
          anchor: Anchor.center,
        ) {
    ammoInMag[WeaponType.pistol] = weaponCatalog[WeaponType.pistol]!.magazineSize;
    ammoReserve[WeaponType.pistol] = 60;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _body = RectangleComponent(
      size: size,
      paint: Paint()..color = skinColor,
      anchor: Anchor.topLeft,
    );
    add(_body);
    add(RectangleHitbox()..collisionType = CollisionType.active);

    parent?.add(SpawnEffect(position: position.clone(), color: skinColor));
  }

  void dash() {
    if (_dashTimer <= 0) {
      _dashTimer = dashCooldown;
      _dashActiveTimer = dashDuration;
      _triggerHaptic();
      game.sfx.playDash();
    }
  }

  void throwGrenade() {
    if (_grenadeTimer <= 0 && aimDirection.length2 > 0) {
      _grenadeTimer = grenadeCooldown;
      final dir = aimDirection.normalized();
      final spawnPos = position + dir * (size.x / 2 + 12);
      parent?.add(Grenade(position: spawnPos, direction: dir));
      game.sfx.playGrenade();
      _triggerHaptic();
    }
  }

  void reload() {
    if (isReloading) return;
    final info = weaponCatalog[currentWeapon]!;
    final inMag = ammoInMag[currentWeapon] ?? 0;
    final reserve = ammoReserve[currentWeapon] ?? 0;
    if (inMag >= info.magazineSize || reserve <= 0) return;
    final needed = info.magazineSize - inMag;
    final toLoad = min(needed, reserve);
    _reloadTimer = 0.8 + info.rarity * 0.15;
    ammoReserve[currentWeapon] = reserve - toLoad;
    Future.delayed(Duration(milliseconds: (_reloadTimer * 1000).toInt()), () {
      if (isMounted) {
        ammoInMag[currentWeapon] = (ammoInMag[currentWeapon] ?? 0) + toLoad;
        game.sfx.playReload();
      }
    });
  }

  void switchToSlot(int slot) {
    if (slot < 0 || slot >= maxSlots) return;
    if (slot != currentSlot) {
      currentSlot = slot;
      currentWeapon = weaponSlots[slot];
      _reloadTimer = 0;
      game.sfx.playSwitch();
      _showFloatingText(weaponCatalog[currentWeapon]!.name,
          weaponCatalog[currentWeapon]!.color);
    }
  }

  void cycleWeapon({bool forward = true}) {
    if (forward) {
      switchToSlot((currentSlot + 1) % maxSlots);
    } else {
      switchToSlot((currentSlot - 1 + maxSlots) % maxSlots);
    }
  }

  void pickupWeapon(WeaponType type) {
    final info = weaponCatalog[type]!;
    if (weaponSlots.contains(type)) {
      ammoReserve[type] = (ammoReserve[type] ?? 0) + info.magazineSize;
      _showFloatingText('+${info.magazineSize} 🔋', info.color);
      return;
    }
    for (int i = 0; i < maxSlots; i++) {
      if (weaponSlots[i] == WeaponType.pistol && i != 0) {
        weaponSlots[i] = type;
        ammoInMag[type] = info.magazineSize;
        ammoReserve[type] = info.magazineSize * 2;
        switchToSlot(i);
        return;
      }
    }
    weaponSlots[currentSlot] = type;
    ammoInMag[type] = info.magazineSize;
    ammoReserve[type] = info.magazineSize * 2;
    currentWeapon = type;
  }

  void addAmmo(WeaponType type, int amount) {
    ammoReserve[type] = (ammoReserve[type] ?? 0) + amount;
    _showFloatingText('+$amount 🔋', weaponCatalog[type]!.color);
  }

  void heal(int amount) {
    final before = hearts;
    hearts = (hearts + amount).clamp(0, maxHearts);
    if (hearts > before) {
      _showFloatingText('+${hearts - before} ❤', const Color(0xFF4CAF50));
      game.sfx.playHeal();
    }
  }

  void addShield() {
    hasShield = true;
    _shieldTimer = 8.0;
    _addShieldVisual();
    _showFloatingText('🛡 Bouclier !', const Color(0xFF7B68EE));
  }

  void shoot() {
    if (isReloading) return;
    final info = weaponCatalog[currentWeapon]!;
    final inMag = ammoInMag[currentWeapon] ?? 0;
    if (inMag <= 0) {
      reload();
      return;
    }
    if (_shootTimer <= 0 && aimDirection.length2 > 0) {
      _shootTimer = info.cooldown;
      ammoInMag[currentWeapon] = inMag - 1;

      final dir = aimDirection.normalized();
      final spawnPos = position + dir * (size.x / 2 + 8);

      final pellets = info.pellets;
      final spread = info.spread;

      for (int i = 0; i < pellets; i++) {
        var pelletDir = dir.clone();
        if (pellets > 1) {
          final spreadAmt = ((i / (pellets - 1)) - 0.5) * 2 * spread;
          final c = cos(spreadAmt);
          final s = sin(spreadAmt);
          pelletDir = Vector2(dir.x * c - dir.y * s, dir.x * s + dir.y * c);
        }

        int dmg = (info.damage).round();
        if (hasDamageBoost) dmg = (dmg * 1.5).round();

        parent?.add(Projectile(
          position: spawnPos,
          direction: pelletDir,
          fromPlayer: true,
          speed: info.speed,
          damage: dmg,
          color: info.color,
          isSniper: currentWeapon == WeaponType.sniper,
          isRocket: currentWeapon == WeaponType.rocket,
        ));
      }

      if (hasDoubleFire) {
        final offset = Vector2(-dir.y, dir.x) * 12;
        parent?.add(Projectile(
          position: spawnPos + offset,
          direction: dir,
          fromPlayer: true,
          speed: info.speed,
          color: info.color,
        ));
      }

      parent?.add(MuzzleFlash(
        position: spawnPos.clone(),
        color: info.color,
      ));

      applyKnockback(-dir * shotKnockback * (0.5 + info.rarity * 0.1));
      game.shakeCamera(strength: 2 + info.rarity * 0.6);

      game.sfx.playShootForWeapon(currentWeapon);
      _triggerHaptic();
    }
  }

  double _meleeActiveWindow = 0;
  bool get isMeleeActive => _meleeActiveWindow > 0;

  void meleeAttack() {
    if (_meleeTimer > 0) return;
    _meleeTimer = meleeCooldown;
    _meleeActiveWindow = 0.14;
    game.sfx.playMelee();
    _triggerHaptic();
  }

  void applyKnockback(Vector2 impulse) {
    knockbackVelocity += impulse;
  }

  void applyPowerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.shield:
        addShield();
        break;
      case PowerUpType.doubleFire:
        hasDoubleFire = true;
        _doubleFireTimer = 10.0;
        _showFloatingText('✨ Double Tir !', const Color(0xFFFFD700));
        break;
      case PowerUpType.speed:
        hasSpeedBoost = true;
        _speedBoostTimer = 8.0;
        _showFloatingText('💨 Vitesse !', const Color(0xFF41E0FF));
        break;
      case PowerUpType.heal:
        heal(2);
        break;
      case PowerUpType.damage:
        hasDamageBoost = true;
        _damageBoostTimer = 10.0;
        _showFloatingText('💪 Dégâts x1.5 !', const Color(0xFFFF4500));
        break;
    }
    game.sfx.playPowerUp();
    game.scoreManager.onPowerUpCollected(position);
  }

  void _addShieldVisual() {
    _shieldVisual?.removeFromParent();
    _shieldVisual = CircleComponent(
      radius: 28,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()
        ..color = const Color(0xFF7B68EE).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
    add(_shieldVisual!);
    add(CircleComponent(
      radius: 28,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()
        ..color = const Color(0xFF7B68EE).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));
  }

  void _removeShieldVisual() {
    _shieldVisual?.removeFromParent();
    _shieldVisual = null;
  }

  void takeHit() {
    if (isDashing) return;
    if (hasShield) {
      hasShield = false;
      _shieldTimer = 0;
      _removeShieldVisual();
      _flashHit(color: const Color(0xFF7B68EE));
      game.sfx.playShieldAbsorb();
      parent?.add(Shockwave(
        position: position.clone(),
        color: const Color(0xFF7B68EE),
        maxRadius: 40,
        duration: 0.25,
      ));
      _triggerHaptic();
      return;
    }
    hearts -= 1;
    _flashHit();
    game.sfx.playHit();
    _triggerHaptic();

    if (hearts == 1) {
      game.sfx.playRageMode();
      parent?.add(Shockwave(
        position: position.clone(),
        color: const Color(0xFFFF4400),
        maxRadius: 50,
        duration: 0.3,
      ));
    }

    if (hearts <= 0) {
      _explode();
    }
  }

  void applyZoneDamage(double dt) {
    if (isDashing || hasShield) return;
    _zoneDamageAccumulator += game.shrinkingZone.damagePerSecond * dt;
    if (_zoneDamageAccumulator >= 1.0) {
      _zoneDamageAccumulator -= 1.0;
      hearts -= 1;
      _flashHit(color: const Color(0xFFFF4444));
      game.sfx.playZoneDamage();
      _triggerHaptic();
      if (hearts <= 0) _explode();
    }
  }

  void _triggerHaptic() {
    if (game.storage.vibrationsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _flashHit({Color? color}) {
    _body.paint.color = color ?? Colors.white;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (isMounted && !isDashing) {
        _body.paint.color = isRageMode ? const Color(0xFFFF4400) : skinColor;
      }
    });
  }

  void _explode() {
    game.sfx.playDeath();
    parent?.add(ConfettiExplosion(position: position.clone()));
    parent?.add(SpawnEffect(
      position: position.clone(),
      color: skinColor,
      reverse: true,
    ));
    parent?.add(Shockwave(
      position: position.clone(),
      color: skinColor,
      maxRadius: 80,
      duration: 0.5,
    ));
    removeFromParent();
  }

  void _showFloatingText(String text, Color color) {
    parent?.add(FloatingText(
      text: text,
      position: position.clone() - Vector2(0, 30),
      color: color,
      fontSize: 13,
    ));
  }

  double get moveSpeed {
    double speed = baseMoveSpeed;
    if (hasSpeedBoost) speed *= 1.5;
    if (isRageMode) speed *= 1.2;
    return speed * game.storage.joystickSensitivity;
  }

  int get meleeDamage {
    int dmg = isRageMode ? 2 : 1;
    if (hasDamageBoost) dmg = (dmg * 1.5).round();
    return dmg;
  }

  int get currentAmmoInMag => ammoInMag[currentWeapon] ?? 0;
  int get currentAmmoReserve => ammoReserve[currentWeapon] ?? 0;

  @override
  void update(double dt) {
    super.update(dt);

    if (_shootTimer > 0) _shootTimer -= dt;
    if (_dashTimer > 0) _dashTimer -= dt;
    if (_meleeTimer > 0) _meleeTimer -= dt;
    if (_meleeActiveWindow > 0) _meleeActiveWindow -= dt;
    if (_grenadeTimer > 0) _grenadeTimer -= dt;
    if (_reloadTimer > 0) _reloadTimer -= dt;

    if (_dashActiveTimer > 0) {
      _dashActiveTimer -= dt;
      _body.paint.color = const Color(0xFFBFF6FF);
      _dashTrailTimer -= dt;
      if (_dashTrailTimer <= 0) {
        _dashTrailTimer = 0.03;
        final vel = moveInput.length2 > 0 ? moveInput.normalized() : aimDirection.normalized();
        parent?.add(DashTrail(
          position: position.clone(),
          velocity: vel * moveSpeed,
          color: skinColor,
        ));
      }
    } else if (_dashActiveTimer <= 0) {
      if (_body.paint.color == const Color(0xFFBFF6FF)) {
        _body.paint.color = isRageMode ? const Color(0xFFFF4400) : skinColor;
      }
    }

    if (isRageMode && !isDashing) {
      _ragePulseTimer += dt;
      if (_ragePulseTimer > 0.35) {
        _ragePulseTimer = 0;
        _ragePulseVisible = !_ragePulseVisible;
        _body.paint.color = _ragePulseVisible
            ? const Color(0xFFFF2200)
            : const Color(0xFFFF7700);
      }
    }

    if (_shieldTimer > 0) {
      _shieldTimer -= dt;
      if (_shieldTimer <= 0) {
        hasShield = false;
        _removeShieldVisual();
      }
    }
    if (_doubleFireTimer > 0) {
      _doubleFireTimer -= dt;
      if (_doubleFireTimer <= 0) hasDoubleFire = false;
    }
    if (_speedBoostTimer > 0) {
      _speedBoostTimer -= dt;
      if (_speedBoostTimer <= 0) hasSpeedBoost = false;
    }
    if (_damageBoostTimer > 0) {
      _damageBoostTimer -= dt;
      if (_damageBoostTimer <= 0) hasDamageBoost = false;
    }

    final combinedInput = moveInput.length2 > 0 ? moveInput : keyboardInput;
    final speedMultiplier = isDashing ? dashSpeedMultiplier : 1.0;
    if (combinedInput.length2 > 0) {
      position += combinedInput.normalized() * moveSpeed * speedMultiplier * dt;
      aimDirection = combinedInput.normalized();
      _stepTimer += dt * moveSpeed;
      if (_stepTimer > 160) {
        _stepTimer = 0;
      }
    }

    if (knockbackVelocity.length2 > 1) {
      position += knockbackVelocity * dt;
      knockbackVelocity *= (1 - knockbackFriction * dt).clamp(0.0, 1.0);
    } else {
      knockbackVelocity = Vector2.zero();
    }

    for (final obs in game.children.query<Obstacle>()) {
      if (obs.type == ObstacleType.bouncePad && obs.toRect().overlaps(toRect())) {
        applyKnockback(aimDirection.normalized() * 520);
        game.shakeCamera(strength: 5);
      }
    }

    final arenaSize = game.size;
    position.x = position.x.clamp(size.x / 2, arenaSize.x - size.x / 2);
    position.y = position.y.clamp(size.y / 2, arenaSize.y - size.y / 2);

    if (!game.shrinkingZone.isInSafeZone(position)) {
      applyZoneDamage(dt);
    } else {
      _zoneDamageAccumulator = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final angle = atan2(aimDirection.y, aimDirection.x);
    final tipDist = size.x / 2 + 8;
    final cx = size.x / 2;
    final cy = size.y / 2;

    final tip = Offset(cx + cos(angle) * tipDist, cy + sin(angle) * tipDist);
    final left = Offset(
      cx + cos(angle + pi * 0.78) * 10,
      cy + sin(angle + pi * 0.78) * 10,
    );
    final right = Offset(
      cx + cos(angle - pi * 0.78) * 10,
      cy + sin(angle - pi * 0.78) * 10,
    );

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    final arrowColor = isRageMode ? const Color(0xFFFF4400) : skinSecondaryColor;
    canvas.drawPath(path, Paint()..color = arrowColor.withValues(alpha: 0.9));

    final info = weaponCatalog[currentWeapon]!;
    final weaponCenter = Offset(cx + cos(angle) * 14, cy + sin(angle) * 14);
    canvas.drawCircle(weaponCenter, 5, Paint()..color = info.color);
    canvas.drawCircle(
      weaponCenter,
      5,
      Paint()
        ..color = info.color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  double get shootCooldownFraction {
    final info = weaponCatalog[currentWeapon]!;
    return _shootTimer / info.cooldown;
  }

  double get dashCooldownFraction => _dashTimer / dashCooldown;
  double get meleeCooldownFraction => _meleeTimer / meleeCooldown;
  double get grenadeCooldownFraction => _grenadeTimer / grenadeCooldown;
  double get reloadFraction {
    final info = weaponCatalog[currentWeapon]!;
    final total = 0.8 + info.rarity * 0.15;
    return _reloadTimer / total;
  }

  double get shieldTimeRemaining => _shieldTimer;
  double get doubleFireTimeRemaining => _doubleFireTimer;
  double get speedTimeRemaining => _speedBoostTimer;
  double get damageTimeRemaining => _damageBoostTimer;
}
