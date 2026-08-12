import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'weapon.dart';
import 'power_up.dart';
import '../spark_arena_game.dart';

enum LootType {
  weapon,
  powerUp,
  heal,
  ammo,
  shield,
}

class LootItem extends PositionComponent
    with CollisionCallbacks, HasGameReference<SparkArenaGame> {
  final LootType lootType;
  final WeaponType? weaponType;
  final PowerUpType? powerUpType;
  final int healAmount;
  final int ammoAmount;

  bool _collected = false;
  double _bobTimer = 0;
  double _pulseTimer = 0;

  LootItem({
    required Vector2 position,
    required this.lootType,
    this.weaponType,
    this.powerUpType,
    this.healAmount = 1,
    this.ammoAmount = 30,
  }) : super(
          position: position,
          size: Vector2.all(32),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(
      radius: 18,
      collisionType: CollisionType.passive,
    ));
  }

  Color get _baseColor {
    switch (lootType) {
      case LootType.weapon:
        return weaponCatalog[weaponType ?? WeaponType.pistol]!.color;
      case LootType.powerUp:
        return PowerUp.colorForType(powerUpType ?? PowerUpType.shield);
      case LootType.heal:
        return const Color(0xFF4CAF50);
      case LootType.ammo:
        return const Color(0xFFFFC107);
      case LootType.shield:
        return const Color(0xFF7B68EE);
    }
  }

  String get _emoji {
    switch (lootType) {
      case LootType.weapon:
        return weaponCatalog[weaponType ?? WeaponType.pistol]!.icon;
      case LootType.powerUp:
        return PowerUp.iconForType(powerUpType ?? PowerUpType.shield);
      case LootType.heal:
        return '💊';
      case LootType.ammo:
        return '📦';
      case LootType.shield:
        return '🛡';
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bobTimer += dt;
    _pulseTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bobOffset = sin(_bobTimer * 3) * 3;
    final pulse = (sin(_pulseTimer * 4) * 0.2 + 0.8).clamp(0.0, 1.0);
    final cx = size.x / 2;
    final cy = size.y / 2 + bobOffset;

    final haloPaint = Paint()
      ..color = _baseColor.withValues(alpha: 0.25 * pulse)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(cx, cy), 22, haloPaint);

    final bgPaint = Paint()
      ..color = _baseColor.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(cx, cy), 15, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), 15, borderPaint);

    final tp = TextPainter(
      text: TextSpan(text: _emoji, style: const TextStyle(fontSize: 18)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - 9, cy - 10));

    if (lootType == LootType.weapon) {
      final info = weaponCatalog[weaponType ?? WeaponType.pistol]!;
      final starTp = TextPainter(
        text: TextSpan(
          text: '⭐' * _weaponRarity(info.type),
          style: const TextStyle(fontSize: 7),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      starTp.paint(canvas, Offset(cx - starTp.width / 2, cy + 10));
    }
  }

  int _weaponRarity(WeaponType type) {
    switch (type) {
      case WeaponType.pistol:
        return 1;
      case WeaponType.smg:
        return 2;
      case WeaponType.ar:
        return 3;
      case WeaponType.shotgun:
        return 3;
      case WeaponType.sniper:
        return 4;
      case WeaponType.tripleLaser:
        return 4;
      case WeaponType.rocket:
        return 5;
    }
  }

  void collect() {
    if (_collected) return;
    _collected = true;
    game.sfx.playPickup();
    removeFromParent();
  }
}

Map<String, String> zoneNames = {
  'topLeft': '🏰 Citadelle',
  'topRight': '🌴 Oasis',
  'center': '⚡ Nexus',
  'bottomLeft': '🌿 Forêt',
  'bottomRight': '🏛️ Ruines',
};
