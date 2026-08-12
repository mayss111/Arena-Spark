import 'dart:math';
import 'package:flame/components.dart';
import 'components/bot.dart';
import 'components/air_drop.dart';
import 'components/kill_announcer.dart';
import 'spark_arena_game.dart';
import 'package:flutter/services.dart';

/// Gère les vagues progressives de bots, airdrops et événements de victoire.
class WaveManager extends Component with HasGameReference<SparkArenaGame> {
  int currentWave = 0;
  bool _waitingForNextWave = false;
  double _interWaveTimer = 0;
  bool _announcementShown = false;
  bool allWavesCompleted = false;

  static const int maxWaves = 10;
  static const double interWaveDelay = 4.0;
  static const int baseBotsPerWave = 2;

  final Random _rnd = Random();

  int botsForWave(int wave) => baseBotsPerWave + (wave - 1) * 2;
  double botSpeedForWave(int wave) => 130.0 + (wave - 1) * 12.0;
  double botShootCooldownForWave(int wave) =>
      (0.75 - (wave - 1) * 0.04).clamp(0.3, 0.75);
  int botHpForWave(int wave) => wave >= 5 ? 4 : 3;

  void start() {
    currentWave = 0;
    allWavesCompleted = false;
    _startNextWave();
  }

  void reset() {
    currentWave = 0;
    _waitingForNextWave = false;
    _interWaveTimer = 0;
    _announcementShown = false;
    allWavesCompleted = false;
  }

  void _startNextWave() {
    currentWave++;
    if (currentWave > maxWaves) {
      allWavesCompleted = true;
      _triggerBooyahVictory();
      return;
    }
    _waitingForNextWave = true;
    _interWaveTimer = currentWave == 1 ? 1.5 : interWaveDelay;
    _announcementShown = false;
  }

  void _triggerBooyahVictory() {
    game.add(KillAnnouncer(
      title: 'BOOYAH ! 🏆',
      subtitle: 'VICTOIRE ROYALE',
      color: const Color(0xFFFFD700),
    ));
    game.shakeCamera(strength: 12, duration: 0.5);
  }

  void _spawnWave() {
    final count = botsForWave(currentWave);
    final arenaSize = game.size;

    for (int i = 0; i < count; i++) {
      final edge = _rnd.nextInt(4);
      double x, y;
      switch (edge) {
        case 0:
          x = _rnd.nextDouble() * arenaSize.x;
          y = 30;
          break;
        case 1:
          x = _rnd.nextDouble() * arenaSize.x;
          y = arenaSize.y - 30;
          break;
        case 2:
          x = 30;
          y = _rnd.nextDouble() * arenaSize.y;
          break;
        default:
          x = arenaSize.x - 30;
          y = _rnd.nextDouble() * arenaSize.y;
          break;
      }

      // Boss sur vagues 5 et 10
      final isBoss = (currentWave == 5 || currentWave == 10) && i == 0;

      // Détermination du type de bot selon la vague
      BotType type = BotType.normal;
      if (!isBoss) {
        if (currentWave == 8) {
          // Vague élite : tous les bots ont un bouclier
          type = BotType.elite;
        } else if (currentWave >= 7 && i % 3 == 2) {
          // Vague 7+ : 1 bot sur 3 est un sniper
          type = BotType.sniper;
        } else if (currentWave >= 9 && i % 2 == 0) {
          // Vague 9-10 : mix élite/sniper
          type = i % 4 == 0 ? BotType.elite : BotType.sniper;
        }
      }

      game.add(Bot(
        position: Vector2(x, y),
        moveSpeedOverride: botSpeedForWave(currentWave),
        shootCooldownOverride: botShootCooldownForWave(currentWave),
        maxHeartsOverride: isBoss ? 10 : (type == BotType.elite ? 5 : botHpForWave(currentWave)),
        isBoss: isBoss,
        botType: type,
      ));
    }

    // Active la zone à partir de la vague 3
    if (currentWave >= 3) {
      game.shrinkingZone.activate();
    }

    // Son de début de vague
    game.sfx.playWaveStart(currentWave);

    // Vibration sur les boss waves
    if (currentWave == 5 || currentWave == 8 || currentWave == 10) {
      HapticFeedback.heavyImpact();
    }

    // Parachute un Airdrop aux vagues 2, 4, 7, 9 !
    if (currentWave == 2 || currentWave == 4 || currentWave == 7 || currentWave == 9) {
      final safe = game.shrinkingZone.safeRect;
      final dropX = safe.left + safe.width * 0.3 + _rnd.nextDouble() * (safe.width * 0.4);
      final dropY = safe.top + safe.height * 0.3 + _rnd.nextDouble() * (safe.height * 0.4);
      game.add(AirDrop(targetPosition: Vector2(dropX, dropY)));
    }
  }

  void onBotEliminated() {}

  @override
  void update(double dt) {
    super.update(dt);

    if (allWavesCompleted) return;

    if (_waitingForNextWave) {
      _interWaveTimer -= dt;

      if (_interWaveTimer <= 2.5 && !_announcementShown) {
        _announcementShown = true;
        game.showWaveAnnouncement(currentWave);
      }

      if (_interWaveTimer <= 0) {
        _waitingForNextWave = false;
        _spawnWave();
      }
      return;
    }

    final botsAlive = game.children.query<Bot>().length;
    if (botsAlive == 0) {
      game.scoreManager.addWaveBonus(currentWave);
      _startNextWave();
    }
  }
}
