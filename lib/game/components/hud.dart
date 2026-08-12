import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'power_up.dart';
import 'weapon.dart';

class Hud extends PositionComponent with HasGameReference {
  int hearts;
  int maxHearts = 5;
  int botsRemaining;
  int waveNumber;
  int score;
  int combo;
  double survivalTime;
  bool isRageMode;

  double shieldTime;
  double doubleFireTime;
  double speedTime;
  double damageTime;

  WeaponType currentWeapon = WeaponType.pistol;
  int ammoInMag = 0;
  int ammoReserve = 0;
  List<WeaponType> weaponSlots = [WeaponType.pistol, WeaponType.pistol];

  late TextComponent _waveText;
  late TextComponent _scoreText;
  late TextComponent _comboText;
  late TextComponent _timerText;
  late TextComponent _botsText;
  late TextComponent _ammoText;
  late TextComponent _weaponNameText;

  Hud({
    this.hearts = 5,
    this.botsRemaining = 0,
    this.waveNumber = 1,
    this.score = 0,
    this.combo = 0,
    this.shieldTime = 0,
    this.doubleFireTime = 0,
    this.speedTime = 0,
    this.damageTime = 0,
    this.survivalTime = 0,
    this.isRageMode = false,
  }) : super(position: Vector2.zero());

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final arenaSize = game.size;

    _botsText = TextComponent(
      text: '👥 $botsRemaining restants',
      position: Vector2(14, 68),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
        ),
      ),
    );
    add(_botsText);

    _waveText = TextComponent(
      text: '🌊 Vague $waveNumber / 10',
      anchor: Anchor.topCenter,
      position: Vector2(arenaSize.x / 2, 14),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF41E0FF),
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          shadows: [Shadow(color: Colors.black45, blurRadius: 3)],
        ),
      ),
    );
    add(_waveText);

    _scoreText = TextComponent(
      text: '⭐ $score',
      anchor: Anchor.topRight,
      position: Vector2(arenaSize.x - 14, 14),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
        ),
      ),
    );
    add(_scoreText);

    _comboText = TextComponent(
      text: '',
      anchor: Anchor.topRight,
      position: Vector2(arenaSize.x - 14, 38),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 14,
          fontWeight: FontWeight.w800,
          shadows: [Shadow(color: Colors.black54, blurRadius: 3)],
        ),
      ),
    );
    add(_comboText);

    _timerText = TextComponent(
      text: '⏱ 0s',
      anchor: Anchor.topCenter,
      position: Vector2(arenaSize.x / 2, 36),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    add(_timerText);

    _ammoText = TextComponent(
      text: '0 / 0',
      anchor: Anchor.bottomRight,
      position: Vector2(arenaSize.x - 14, arenaSize.y - 200),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
        ),
      ),
    );
    add(_ammoText);

    _weaponNameText = TextComponent(
      text: weaponCatalog[currentWeapon]!.name,
      anchor: Anchor.bottomRight,
      position: Vector2(arenaSize.x - 14, arenaSize.y - 172),
      textRenderer: TextPaint(
        style: TextStyle(
          color: weaponCatalog[currentWeapon]!.color,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 3)],
        ),
      ),
    );
    add(_weaponNameText);
  }

  void updateHearts(int value) {
    hearts = value;
  }

  void updateBots(int value) {
    botsRemaining = value;
    if (!isLoaded) return;
    _botsText.text = '👥 $botsRemaining restants';
  }

  void updateWave(int value) {
    waveNumber = value;
    if (!isLoaded) return;
    _waveText.text = '🌊 Vague $waveNumber / 10';
  }

  void updateScore(int value) {
    score = value;
    if (!isLoaded) return;
    _scoreText.text = '⭐ $score';
  }

  void updateCombo(int value) {
    combo = value;
    if (!isLoaded) return;
    _comboText.text = value > 1 ? '🔥 Combo x$value' : '';
  }

  void updateSurvivalTime(double t) {
    survivalTime = t;
    if (!isLoaded) return;
    final mins = (t ~/ 60);
    final secs = (t % 60).floor();
    _timerText.text = mins > 0 ? '⏱ ${mins}m${secs.toString().padLeft(2, '0')}s' : '⏱ ${secs}s';
  }

  void updateRageMode(bool rage) {
    isRageMode = rage;
  }

  void updatePowerUps({
    double shield = 0,
    double doubleFire = 0,
    double speed = 0,
    double damage = 0,
  }) {
    shieldTime = shield;
    doubleFireTime = doubleFire;
    speedTime = speed;
    damageTime = damage;
  }

  void updateWeaponInfo(
    WeaponType wpn,
    int inMag,
    int reserve,
    List<WeaponType> slots,
  ) {
    currentWeapon = wpn;
    ammoInMag = inMag;
    ammoReserve = reserve;
    weaponSlots = List.from(slots);
    if (!isLoaded) return;
    _ammoText.text = '$ammoInMag / $ammoReserve';
    final info = weaponCatalog[currentWeapon]!;
    _weaponNameText.text = '${info.icon} ${info.name}';
    _weaponNameText.textRenderer = TextPaint(
      style: TextStyle(
        color: info.color,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        shadows: const [Shadow(color: Colors.black54, blurRadius: 3)],
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isLoaded) return;

    final arenaVec = game.size;
    final arenaSize = Size(arenaVec.x, arenaVec.y);

    _drawHealthBar(canvas);
    _drawWeaponSlots(canvas, arenaSize);
    _drawPowerUpIcons(canvas, arenaSize);
  }

  void _drawHealthBar(Canvas canvas) {
    const barX = 14.0;
    const barY = 14.0;
    const barW = 200.0;
    const barH = 22.0;
    const heartW = barW / 5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(barX - 2, barY - 2, barW + 4, barH + 4),
        const Radius.circular(8),
      ),
      Paint()
        ..color = Colors.black54
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(barX, barY, barW, barH),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF1a1a2e),
    );

    final hpFrac = (hearts / maxHearts).clamp(0.0, 1.0);
    final gradColor1 = isRageMode ? const Color(0xFFFF4500) : const Color(0xFF41E0FF);
    final gradColor2 = isRageMode ? const Color(0xFFFF8C00) : const Color(0xFF7B68EE);
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [gradColor1, gradColor2],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(barX, barY, barW * hpFrac, barH));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barX, barY, barW * hpFrac, barH),
        const Radius.circular(6),
      ),
      fillPaint,
    );

    for (int i = 1; i < maxHearts; i++) {
      canvas.drawLine(
        Offset(barX + heartW * i, barY),
        Offset(barX + heartW * i, barY + barH),
        Paint()..color = Colors.black38,
      );
    }

    for (int i = 0; i < maxHearts; i++) {
      final cx = barX + heartW * i + heartW / 2;
      const cy = barY + barH / 2;
      final filled = i < hearts;
      final tp = TextPainter(
        text: TextSpan(
          text: filled ? '❤' : '🖤',
          style: TextStyle(
            fontSize: 14,
            color: filled
                ? (isRageMode ? Colors.orange : Colors.red)
                : Colors.white24,
            shadows: filled
                ? const [Shadow(color: Colors.black54, blurRadius: 2)]
                : null,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
  }

  void _drawWeaponSlots(Canvas canvas, Size arenaSize) {
    const slotW = 58.0;
    const slotH = 62.0;
    final startX = arenaSize.width - slotW * 2 - 22;
    final y = arenaSize.height - 280;

    for (int i = 0; i < 2; i++) {
      final x = startX + i * (slotW + 8);
      final wpn = weaponSlots.length > i ? weaponSlots[i] : WeaponType.pistol;
      final info = weaponCatalog[wpn]!;
      final active = (i == 0 && weaponSlots[0] == currentWeapon) ||
          (i == 1 && weaponSlots[1] == currentWeapon);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, slotW, slotH),
          const Radius.circular(10),
        ),
        Paint()
          ..color = active
              ? info.color.withValues(alpha: 0.25)
              : Colors.black.withValues(alpha: 0.5),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, slotW, slotH),
          const Radius.circular(10),
        ),
        Paint()
          ..color = active ? info.color : Colors.white12
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 2.5 : 1,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: info.icon,
          style: TextStyle(
            fontSize: 26,
            color: info.color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x + slotW / 2 - tp.width / 2, y + 10));

      final slotLabel = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: active ? info.color : Colors.white54,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      slotLabel.paint(canvas, Offset(x + 4, y + 4));

      final stars = '⭐' * info.rarity;
      final starTp = TextPainter(
        text: TextSpan(
          text: stars,
          style: const TextStyle(fontSize: 7),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      starTp.paint(
          canvas, Offset(x + slotW / 2 - starTp.width / 2, y + slotH - 14));
    }
  }

  void _drawPowerUpIcons(Canvas canvas, Size arenaSize) {
    double iconX = 14;
    final iconY = arenaSize.height - 44;

    void drawPowerUpIcon(PowerUpType type, double remaining) {
      if (remaining <= 0) return;
      final color = PowerUp.colorForType(type);
      final icon = PowerUp.iconForType(type);

      final bgPaint = Paint()
        ..color = color.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(iconX, iconY, 44, 40),
          const Radius.circular(10),
        ),
        bgPaint,
      );

      final borderPaint = Paint()
        ..color = color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(iconX, iconY, 44, 40),
          const Radius.circular(10),
        ),
        borderPaint,
      );

      final tp = TextPainter(
        text: TextSpan(text: icon, style: const TextStyle(fontSize: 18)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(iconX + 13, iconY + 5));

      final fraction = (remaining / _maxTime(type)).clamp(0.0, 1.0);
      final barPaint = Paint()..color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(iconX, iconY + 34, 44 * fraction, 4),
          const Radius.circular(2),
        ),
        barPaint,
      );

      iconX += 52;
    }

    drawPowerUpIcon(PowerUpType.shield, shieldTime);
    drawPowerUpIcon(PowerUpType.doubleFire, doubleFireTime);
    drawPowerUpIcon(PowerUpType.speed, speedTime);
    drawPowerUpIcon(PowerUpType.damage, damageTime);
  }

  double _maxTime(PowerUpType type) {
    switch (type) {
      case PowerUpType.shield:
        return 8.0;
      case PowerUpType.doubleFire:
        return 10.0;
      case PowerUpType.speed:
        return 8.0;
      case PowerUpType.heal:
        return 1.0;
      case PowerUpType.damage:
        return 10.0;
    }
  }
}
