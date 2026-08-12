
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'spark_arena_game.dart';

/// Gère le score, les combos et les bonus.
class ScoreManager extends Component with HasGameReference<SparkArenaGame> {
  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  int totalKills = 0;
  double _comboTimer = 0;

  static const double comboWindow = 3.0; // secondes pour maintenir le combo
  static const int killBasePoints = 100;
  static const int powerUpPoints = 25;
  static const int waveBonusBase = 50;

  /// Appelé quand le joueur élimine un bot.
  void onKill(Vector2 position, {bool isBoss = false, String botType = 'normal'}) {
    combo++;
    totalKills++;
    _comboTimer = comboWindow;
    if (combo > maxCombo) maxCombo = combo;

    final multiplier = combo.clamp(1, 5);
    final basePoints = isBoss
        ? 500
        : (botType == 'elite' ? 150 : (botType == 'sniper' ? 120 : killBasePoints));
    final points = basePoints * multiplier;
    score += points;

    // Afficher le popup de score
    final label = isBoss ? '👑 BOSS +$points' : '+$points${combo > 1 ? ' x$combo' : ''}';
    game.add(ScorePopup(
      position: position.clone(),
      text: label,
      color: isBoss
          ? const Color(0xFFFFD700)
          : (combo > 1 ? const Color(0xFFFF9944) : Colors.white),
      large: isBoss || combo >= 3,
    ));
  }

  /// Appelé quand le joueur ramasse un power-up.
  void onPowerUpCollected(Vector2 position) {
    score += powerUpPoints;
    game.add(ScorePopup(
      position: position.clone(),
      text: '+$powerUpPoints',
      color: const Color(0xFF00FF7F),
    ));
  }

  /// Bonus de fin de vague.
  void addWaveBonus(int waveNumber) {
    final bonus = waveBonusBase * waveNumber;
    score += bonus;
    game.add(ScorePopup(
      position: game.size / 2,
      text: 'Vague $waveNumber : +$bonus',
      color: const Color(0xFF41E0FF),
      large: true,
    ));
  }

  void reset() {
    score = 0;
    combo = 0;
    maxCombo = 0;
    totalKills = 0;
    _comboTimer = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_comboTimer > 0) {
      _comboTimer -= dt;
      if (_comboTimer <= 0) {
        combo = 0;
      }
    }
  }
}

/// Popup flottant de score qui monte et disparaît.
class ScorePopup extends PositionComponent {
  final String text;
  final Color color;
  final bool large;
  double _age = 0;
  static const double lifetime = 1.2;

  ScorePopup({
    required Vector2 position,
    required this.text,
    this.color = Colors.white,
    this.large = false,
  }) : super(position: position);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y -= 60 * dt; // Monte doucement
    if (_age >= lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final opacity = (1.0 - (_age / lifetime)).clamp(0.0, 1.0);
    final scale = large ? 1.3 : 1.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color.withValues(alpha: opacity),
          fontSize: 18 * scale,
          fontWeight: FontWeight.w800,
          shadows: [
            Shadow(
              color: color.withValues(alpha: opacity * 0.5),
              blurRadius: 8,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
  }
}
