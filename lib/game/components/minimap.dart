
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'bot.dart';
import 'air_drop.dart';
import 'loot_item.dart';
import 'weapon.dart';
import '../spark_arena_game.dart';

class MiniMapHud extends PositionComponent with HasGameReference<SparkArenaGame> {
  static const double mapSize = 110;
  static const List<Map<String, dynamic>> _zones = [
    {'name': 'Citadelle', 'x': 0.75, 'y': 0.25, 'color': Color(0xFF7B68EE)},
    {'name': 'Oasis', 'x': 0.2, 'y': 0.2, 'color': Color(0xFF32CD32)},
    {'name': 'Nexus', 'x': 0.5, 'y': 0.5, 'color': Color(0xFFFF6B6B)},
    {'name': 'Forêt', 'x': 0.25, 'y': 0.8, 'color': Color(0xFF228B22)},
    {'name': 'Ruines', 'x': 0.8, 'y': 0.75, 'color': Color(0xFFFF8C00)},
  ];

  MiniMapHud()
      : super(
          size: Vector2.all(mapSize),
          position: Vector2(0, 0),
          anchor: Anchor.topRight,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(game.size.x - 14, 60);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final worldSize = game.size;
    final scaleX = mapSize / worldSize.x;
    final scaleY = mapSize / worldSize.y;

    final bgRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, mapSize, mapSize),
      const Radius.circular(14),
    );
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0A0E1A),
          Color(0xFF1A1033),
        ],
      ).createShader(Offset.zero & const Size(mapSize, mapSize));
    canvas.drawRRect(bgRect, bgPaint);

    final borderPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF41E0FF),
          Color(0xFF8A2BE2),
          Color(0xFFFF6B6B),
        ],
      ).createShader(Offset.zero & const Size(mapSize, mapSize))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(bgRect, borderPaint);

    final gridPaint = Paint()
      ..color = const Color(0xFF41E0FF).withValues(alpha: 0.08)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 5; i++) {
      final p = (i / 5) * mapSize;
      canvas.drawLine(Offset(p, 0), Offset(p, mapSize), gridPaint);
      canvas.drawLine(Offset(0, p), Offset(mapSize, p), gridPaint);
    }

    for (final zone in _zones) {
      final zx = (zone['x'] as double) * mapSize;
      final zy = (zone['y'] as double) * mapSize;
      final zColor = zone['color'] as Color;

      final zoneBg = Paint()
        ..color = zColor.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(zx, zy), mapSize * 0.14, zoneBg);

      final zoneRing = Paint()
        ..color = zColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawCircle(Offset(zx, zy), mapSize * 0.12, zoneRing);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: zone['name'] as String,
          style: TextStyle(
            color: zColor.withValues(alpha: 0.7),
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(canvas, Offset(zx - labelPainter.width / 2, zy - 4));
    }

    final safe = game.shrinkingZone.safeRect;
    final miniSafeRect = Rect.fromLTRB(
      safe.left * scaleX,
      safe.top * scaleY,
      safe.right * scaleX,
      safe.bottom * scaleY,
    );
    final zoneFill = Paint()
      ..color = const Color(0xFF41E0FF).withValues(alpha: 0.08);
    canvas.drawRect(miniSafeRect, zoneFill);
    final zonePaint = Paint()
      ..color = const Color(0xFF41E0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRect(miniSafeRect, zonePaint);

    for (final loot in game.children.query<LootItem>()) {
      final lp = Offset(loot.position.x * scaleX, loot.position.y * scaleY);
      Color c = Colors.white;
      double sz = 2.0;
      switch (loot.lootType) {
        case LootType.weapon:
          c = loot.weaponType != null
              ? (weaponCatalog[loot.weaponType]?.rarity ?? 1) >= 4
                  ? const Color(0xFFFF00FF)
                  : const Color(0xFFFFD700)
              : const Color(0xFFFFD700);
          sz = 2.8;
          break;
        case LootType.powerUp:
          c = const Color(0xFF00FFFF);
          sz = 2.5;
          break;
        case LootType.heal:
          c = const Color(0xFF00FF66);
          sz = 2.3;
          break;
        case LootType.ammo:
          c = const Color(0xFFFFB347);
          sz = 1.8;
          break;
        case LootType.shield:
          c = const Color(0xFF4169E1);
          sz = 2.3;
          break;
      }
      final pulse = 0.7 + 0.3 * sin(DateTime.now().millisecondsSinceEpoch / 250 + loot.position.x * 0.01);
      final lpPaint = Paint()
        ..color = c.withValues(alpha: pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(lp, sz * 1.6, lpPaint);
      final lpSolid = Paint()..color = c;
      canvas.drawCircle(lp, sz, lpSolid);
    }

    for (final ad in game.children.query<AirDrop>()) {
      final adPos = Offset(ad.position.x * scaleX, ad.position.y * scaleY);
      final glow = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(adPos, 7, glow);
      final adPaint = Paint()..color = const Color(0xFFFFD700);
      canvas.drawCircle(adPos, 4, adPaint);
      final starPainter = TextPainter(
        text: const TextSpan(
          text: '✦',
          style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.w900),
        ),
        textDirection: TextDirection.ltr,
      );
      starPainter.layout();
      starPainter.paint(canvas, Offset(adPos.dx - starPainter.width / 2, adPos.dy - starPainter.height / 2 - 1));
    }

    for (final bot in game.children.query<Bot>()) {
      final botPos = Offset(bot.position.x * scaleX, bot.position.y * scaleY);
      final botGlow = Paint()
        ..color = const Color(0xFFFF4444).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(botPos, 4, botGlow);
      final botPaint = Paint()
        ..color = bot.isBoss ? const Color(0xFFFF00FF) : const Color(0xFFFF4444);
      canvas.drawCircle(botPos, bot.isBoss ? 3.2 : 2.6, botPaint);
      if (bot.isBoss) {
        final ring = Paint()
          ..color = const Color(0xFFFF00FF).withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7;
        canvas.drawCircle(botPos, 5, ring);
      }
    }

    if (game.player.isMounted) {
      final playerPos =
          Offset(game.player.position.x * scaleX, game.player.position.y * scaleY);
      final pulseT = DateTime.now().millisecondsSinceEpoch / 300;
      final pulseR = 5 + sin(pulseT) * 1.5;
      final haloPaint = Paint()
        ..color = const Color(0xFF41E0FF).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(playerPos, pulseR + 4, haloPaint);
      final halo2 = Paint()
        ..color = const Color(0xFF41E0FF).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(playerPos, pulseR, halo2);
      final playerPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final playerRing = Paint()
        ..color = const Color(0xFF41E0FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(playerPos, 4, playerPaint);
      canvas.drawCircle(playerPos, 4, playerRing);
    }

    final titlePainter = TextPainter(
      text: const TextSpan(
        text: '◈ CARTE ◈',
        style: TextStyle(
          color: Color(0xFF41E0FF),
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    final titleBg = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawRect(
      Rect.fromLTWH(mapSize / 2 - titlePainter.width / 2 - 6, mapSize - 13,
          titlePainter.width + 12, 12),
      titleBg,
    );
    titlePainter.paint(
        canvas, Offset(mapSize / 2 - titlePainter.width / 2, mapSize - 11.5));
  }
}
