import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import '../components/weapon.dart';

/// SfxEngine — Moteur de sons procéduraux.
/// Génère des fichiers WAV en mémoire et les joue via AudioPlayer.
/// Aucun fichier audio externe nécessaire.
class SfxEngine {
  static const int _sampleRate = 22050;

  final _pool = <AudioPlayer>[];
  static const int _poolSize = 12;
  int _poolIndex = 0;

  bool enabled = true;
  double volume = 0.7;

  SfxEngine() {
    for (int i = 0; i < _poolSize; i++) {
      _pool.add(AudioPlayer());
    }
  }

  AudioPlayer _nextPlayer() {
    final p = _pool[_poolIndex % _poolSize];
    _poolIndex++;
    return p;
  }

  Future<void> dispose() async {
    for (final p in _pool) {
      await p.dispose();
    }
  }

  // ─── API publique ─────────────────────────────────────────────────────────

  void playShoot() => _play(_generateShoot());
  void playTripleLaser() => _play(_generateLaser());
  void playShotgun() => _play(_generateShotgun());
  void playHit() => _play(_generateHit());
  void playBotExplosion({bool isBoss = false}) =>
      _play(_generateExplosion(isBoss: isBoss));
  void playPowerUp() => _play(_generatePowerUp());
  void playDash() => _play(_generateDash());
  void playZoneDamage() => _play(_generateZoneTick());
  void playVictory() => _play(_generateVictory());
  void playDeath() => _play(_generateDeath());
  void playMelee() => _play(_generateMelee());
  void playGrenade() => _play(_generateGrenade());
  void playGrenadeExplosion() => _play(_generateGrenadeExplosion());
  void playShieldAbsorb() => _play(_generateShieldAbsorb());
  void playRageMode() => _play(_generateRageActivate());
  void playLuckyDrop() => _play(_generateLuckyDrop());
  void playEliteShieldBreak() => _play(_generateEliteBreak());
  void playWaveStart(int wave) => _play(_generateWaveChime(wave));
  void playReload() => _play(_generateReload());
  void playSwitch() => _play(_generateSwitch());
  void playPickup() => _play(_generatePickup());
  void playHeal() => _play(_generateHeal());
  void playShootForWeapon(WeaponType t) {
    switch (t) {
      case WeaponType.pistol:
        playShoot();
        break;
      case WeaponType.smg:
        _play(_generateSmg());
        break;
      case WeaponType.ar:
        _play(_generateAr());
        break;
      case WeaponType.shotgun:
        playShotgun();
        break;
      case WeaponType.sniper:
        _play(_generateSniper());
        break;
      case WeaponType.tripleLaser:
        playTripleLaser();
        break;
      case WeaponType.rocket:
        _play(_generateRocket());
        break;
    }
  }

  // ─── Moteur ───────────────────────────────────────────────────────────────

  Future<void> _play(Uint8List wav) async {
    if (!enabled) return;
    final player = _nextPlayer();
    await player.setVolume(volume);
    await player.play(BytesSource(wav));
  }

  Uint8List _buildWav(Float32List samples) {
    final numSamples = samples.length;
    final dataSize = numSamples * 2;
    final fileSize = 44 + dataSize;

    final buf = ByteData(fileSize);
    // RIFF header
    buf.setUint8(0, 0x52); buf.setUint8(1, 0x49); buf.setUint8(2, 0x46); buf.setUint8(3, 0x46);
    buf.setUint32(4, fileSize - 8, Endian.little);
    buf.setUint8(8, 0x57); buf.setUint8(9, 0x41); buf.setUint8(10, 0x56); buf.setUint8(11, 0x45);
    // fmt chunk
    buf.setUint8(12, 0x66); buf.setUint8(13, 0x6D); buf.setUint8(14, 0x74); buf.setUint8(15, 0x20);
    buf.setUint32(16, 16, Endian.little);
    buf.setUint16(20, 1, Endian.little);  // PCM
    buf.setUint16(22, 1, Endian.little);  // mono
    buf.setUint32(24, _sampleRate, Endian.little);
    buf.setUint32(28, _sampleRate * 2, Endian.little);
    buf.setUint16(32, 2, Endian.little);
    buf.setUint16(34, 16, Endian.little);
    // data chunk
    buf.setUint8(36, 0x64); buf.setUint8(37, 0x61); buf.setUint8(38, 0x74); buf.setUint8(39, 0x61);
    buf.setUint32(40, dataSize, Endian.little);
    for (int i = 0; i < numSamples; i++) {
      final clamped = samples[i].clamp(-1.0, 1.0);
      final int16 = (clamped * 32767).round();
      buf.setInt16(44 + i * 2, int16, Endian.little);
    }
    return buf.buffer.asUint8List();
  }

  // ─── Synthèse des sons ───────────────────────────────────────────────────

  /// Tir pistolet — descente rapide 400Hz → 150Hz
  Uint8List _generateShoot() {
    const dur = 0.08;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = i / n;
      final freq = 400 - 250 * progress;
      final envelope = (1 - progress) * (1 - progress);
      s[i] = sin(2 * pi * freq * t) * envelope * 0.8;
    }
    return _buildWav(s);
  }

  /// Laser triple — buzz électrique
  Uint8List _generateLaser() {
    const dur = 0.1;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    final rng = Random();
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = i / n;
      final freq = 880 - 220 * progress;
      final env = (1 - progress);
      // Onde carrée + noise
      final wave = (sin(2 * pi * freq * t) > 0 ? 1.0 : -1.0) * 0.5;
      final noise = (rng.nextDouble() * 2 - 1) * 0.1;
      s[i] = (wave + noise) * env * 0.6;
    }
    return _buildWav(s);
  }

  /// Shotgun — burst large
  Uint8List _generateShotgun() {
    const dur = 0.15;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    final rng = Random();
    for (int i = 0; i < n; i++) {
      final progress = i / n;
      final env = exp(-progress * 8);
      final noise = (rng.nextDouble() * 2 - 1);
      final tone = sin(2 * pi * (200 - 150 * progress) * i / _sampleRate);
      s[i] = (noise * 0.6 + tone * 0.4) * env * 0.9;
    }
    return _buildWav(s);
  }

  /// Impact — thud court
  Uint8List _generateHit() {
    const dur = 0.06;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    final rng = Random();
    for (int i = 0; i < n; i++) {
      final progress = i / n;
      final env = exp(-progress * 12);
      s[i] = ((rng.nextDouble() * 2 - 1) * 0.7 +
          sin(2 * pi * 120 * i / _sampleRate) * 0.3) * env * 0.8;
    }
    return _buildWav(s);
  }

  /// Explosion bot — boom grave
  Uint8List _generateExplosion({bool isBoss = false}) {
    final dur = isBoss ? 0.4 : 0.2;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    final rng = Random();
    for (int i = 0; i < n; i++) {
      final progress = i / n;
      final env = exp(-progress * (isBoss ? 5 : 8));
      final baseFreq = isBoss ? 80.0 : 120.0;
      final tone = sin(2 * pi * (baseFreq - progress * 60) * i / _sampleRate);
      final noise = (rng.nextDouble() * 2 - 1);
      s[i] = (tone * 0.5 + noise * 0.5) * env * (isBoss ? 1.0 : 0.85);
    }
    return _buildWav(s);
  }

  /// Power-up collecté — arpège montant C→E→G
  Uint8List _generatePowerUp() {
    const dur = 0.25;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    // C4=261Hz, E4=329Hz, G4=392Hz
    const freqs = [261.0, 329.0, 392.0];
    final segLen = n ~/ 3;
    for (int i = 0; i < n; i++) {
      final seg = (i ~/ segLen).clamp(0, 2);
      final t = i / _sampleRate;
      final localProgress = (i % segLen) / segLen;
      final env = sin(pi * localProgress); // bell shape
      s[i] = sin(2 * pi * freqs[seg] * t) * env * 0.7;
    }
    return _buildWav(s);
  }

  /// Dash — whoosh
  Uint8List _generateDash() {
    const dur = 0.12;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    final rng = Random();
    for (int i = 0; i < n; i++) {
      final progress = i / n;
      final env = sin(pi * progress); // montée puis descente
      final noise = (rng.nextDouble() * 2 - 1);
      final pitch = sin(2 * pi * (600 + 200 * progress) * i / _sampleRate) * 0.3;
      s[i] = (noise * 0.6 + pitch) * env * 0.65;
    }
    return _buildWav(s);
  }

  /// Dommage zone — crépitement
  Uint8List _generateZoneTick() {
    const dur = 0.05;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    final rng = Random();
    for (int i = 0; i < n; i++) {
      final progress = i / n;
      s[i] = (rng.nextDouble() * 2 - 1) * exp(-progress * 15) * 0.7;
    }
    return _buildWav(s);
  }

  /// Victoire — fanfare montante
  Uint8List _generateVictory() {
    const dur = 0.6;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    // Mi-Sol-Do montant
    const freqs = [329.0, 392.0, 523.0, 659.0];
    final segLen = n ~/ 4;
    for (int i = 0; i < n; i++) {
      final seg = (i ~/ segLen).clamp(0, 3);
      final t = i / _sampleRate;
      final localProgress = (i % segLen) / segLen;
      final env = sin(pi * localProgress);
      final chord = sin(2 * pi * freqs[seg] * t) +
          sin(2 * pi * freqs[seg] * 1.5 * t) * 0.3;
      s[i] = chord * env * 0.5;
    }
    return _buildWav(s);
  }

  /// Mort joueur — descente chromatique triste
  Uint8List _generateDeath() {
    const dur = 0.4;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = i / n;
      final freq = 400 - 300 * progress;
      final env = (1 - progress) * sin(pi * progress * 0.5);
      s[i] = sin(2 * pi * freq * t) * env * 0.8;
    }
    return _buildWav(s);
  }

  /// Mêlée — impact sourd
  Uint8List _generateMelee() {
    const dur = 0.08;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    final rng = Random();
    for (int i = 0; i < n; i++) {
      final progress = i / n;
      final env = exp(-progress * 10);
      s[i] = ((rng.nextDouble() * 2 - 1) * 0.5 +
          sin(2 * pi * 180 * i / _sampleRate) * 0.5) * env * 0.9;
    }
    return _buildWav(s);
  }

  /// Grenade lancée — sifflement
  Uint8List _generateGrenade() {
    const dur = 0.1;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = i / n;
      final freq = 800 + 400 * progress;
      s[i] = sin(2 * pi * freq * t) * (1 - progress) * 0.5;
    }
    return _buildWav(s);
  }

  /// Explosion grenade — plus grande et percutante
  Uint8List _generateGrenadeExplosion() {
    const dur = 0.35;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    final rng = Random();
    for (int i = 0; i < n; i++) {
      final progress = i / n;
      final env = exp(-progress * 6);
      final sub = sin(2 * pi * (60 - progress * 40) * i / _sampleRate);
      final noise = (rng.nextDouble() * 2 - 1);
      s[i] = (sub * 0.6 + noise * 0.4) * env * 1.0;
    }
    return _buildWav(s);
  }

  /// Bouclier absorbe — ding cristallin
  Uint8List _generateShieldAbsorb() {
    const dur = 0.15;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = i / n;
      final env = exp(-progress * 8);
      s[i] = (sin(2 * pi * 1200 * t) * 0.5 +
          sin(2 * pi * 1800 * t) * 0.3) * env * 0.7;
    }
    return _buildWav(s);
  }

  /// Rage Mode activé — grondement montant
  Uint8List _generateRageActivate() {
    const dur = 0.3;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    final rng = Random();
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = i / n;
      final freq = 100 + 200 * progress;
      final env = sin(pi * progress * 0.7);
      final noise = (rng.nextDouble() * 2 - 1) * 0.2;
      s[i] = (sin(2 * pi * freq * t) * 0.8 + noise) * env * 0.8;
    }
    return _buildWav(s);
  }

  /// Lucky Drop — pièce magique
  Uint8List _generateLuckyDrop() {
    const dur = 0.18;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = i / n;
      final env = sin(pi * progress);
      s[i] = (sin(2 * pi * 523 * t) * 0.5 +
          sin(2 * pi * 784 * t) * 0.3) * env * 0.6;
    }
    return _buildWav(s);
  }

  /// Bouclier élite brisé — craquement électrique
  Uint8List _generateEliteBreak() {
    const dur = 0.2;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    final rng = Random();
    for (int i = 0; i < n; i++) {
      final progress = i / n;
      final env = exp(-progress * 7);
      final crackle = (rng.nextDouble() * 2 - 1);
      final tone = sin(2 * pi * 1000 * i / _sampleRate * (1 - progress * 0.5));
      s[i] = (crackle * 0.6 + tone * 0.4) * env * 0.8;
    }
    return _buildWav(s);
  }

  /// Chime de début de vague
  Uint8List _generateWaveChime(int wave) {
    const dur = 0.22;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    final baseFreq = 440.0 + wave * 20;
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = i / n;
      final env = exp(-progress * 6);
      s[i] = (sin(2 * pi * baseFreq * t) * 0.6 +
          sin(2 * pi * baseFreq * 2 * t) * 0.2) * env * 0.65;
    }
    return _buildWav(s);
  }

  Uint8List _generateReload() {
    const dur = 0.35;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = i / n;
      final clickPhase = (progress * 5).floor();
      final localProgress = (progress * 5) % 1;
      final freq = 800.0 + clickPhase * 200;
      final env = exp(-localProgress * 12);
      s[i] = sin(2 * pi * freq * t) * env * 0.5;
    }
    return _buildWav(s);
  }

  Uint8List _generateSwitch() {
    const dur = 0.12;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = i / n;
      final env = sin(pi * progress);
      final freq = 300 + 500 * progress;
      s[i] = sin(2 * pi * freq * t) * env * 0.55;
    }
    return _buildWav(s);
  }

  Uint8List _generatePickup() {
    const dur = 0.18;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    const freqs = [660.0, 880.0, 1100.0];
    final segLen = n ~/ 3;
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final seg = (i ~/ segLen).clamp(0, 2);
      final localProgress = (i % segLen) / segLen;
      final env = sin(pi * localProgress);
      s[i] = sin(2 * pi * freqs[seg] * t) * env * 0.55;
    }
    return _buildWav(s);
  }

  Uint8List _generateHeal() {
    const dur = 0.4;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = i / n;
      final env = sin(pi * progress);
      final chord = sin(2 * pi * 523 * t) +
          sin(2 * pi * 659 * t) * 0.5 +
          sin(2 * pi * 784 * t) * 0.3;
      s[i] = chord * env * 0.35;
    }
    return _buildWav(s);
  }

  Uint8List _generateSmg() {
    const dur = 0.05;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    final rng = Random();
    for (int i = 0; i < n; i++) {
      final progress = i / n;
      final env = exp(-progress * 18);
      final freq = 600 - 200 * progress;
      final wave = (sin(2 * pi * freq * i / _sampleRate) > 0 ? 1.0 : -1.0) * 0.4;
      final noise = (rng.nextDouble() * 2 - 1) * 0.25;
      s[i] = (wave + noise) * env * 0.7;
    }
    return _buildWav(s);
  }

  Uint8List _generateAr() {
    const dur = 0.07;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    final rng = Random();
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = i / n;
      final env = exp(-progress * 14);
      final freq = 350 - 150 * progress;
      final noise = (rng.nextDouble() * 2 - 1) * 0.4;
      final tone = sin(2 * pi * freq * t) * 0.6;
      s[i] = (tone + noise) * env * 0.8;
    }
    return _buildWav(s);
  }

  Uint8List _generateSniper() {
    const dur = 0.25;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    final rng = Random();
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = i / n;
      final env = exp(-progress * 6);
      final freq = 200 + 400 * exp(-progress * 8);
      final tone = sin(2 * pi * freq * t) * 0.5;
      final noise = (rng.nextDouble() * 2 - 1) * 0.5;
      final whoosh = sin(2 * pi * (1200 - 900 * progress) * t) * 0.2;
      s[i] = (tone + noise + whoosh) * env * 0.85;
    }
    return _buildWav(s);
  }

  Uint8List _generateRocket() {
    const dur = 0.35;
    final n = (dur * _sampleRate).round();
    final s = Float32List(n);
    final rng = Random();
    for (int i = 0; i < n; i++) {
      final t = i / _sampleRate;
      final progress = i / n;
      final env = exp(-progress * 4);
      final bass = sin(2 * pi * (100 + progress * 50) * t) * 0.6;
      final noise = (rng.nextDouble() * 2 - 1) * 0.5;
      final whoosh = sin(2 * pi * (300 + 200 * progress) * t) * 0.25;
      s[i] = (bass + noise + whoosh) * env * 0.9;
    }
    return _buildWav(s);
  }
}
