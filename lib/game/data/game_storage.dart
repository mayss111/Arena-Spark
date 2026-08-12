import 'package:shared_preferences/shared_preferences.dart';

/// Gère la persistence locale (scores, skins, réglages).
class GameStorage {
  static GameStorage? _instance;
  late SharedPreferences _prefs;

  GameStorage._();

  static Future<GameStorage> getInstance() async {
    if (_instance == null) {
      _instance = GameStorage._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // --- High Score ---
  int get highScore => _prefs.getInt('highScore') ?? 0;
  Future<void> setHighScore(int value) async {
    if (value > highScore) {
      await _prefs.setInt('highScore', value);
    }
  }

  // --- Score cumulé (pour débloquer les skins) ---
  int get totalScore => _prefs.getInt('totalScore') ?? 0;
  Future<void> addToTotalScore(int value) async {
    await _prefs.setInt('totalScore', totalScore + value);
  }

  // --- Vague max atteinte ---
  int get maxWave => _prefs.getInt('maxWave') ?? 0;
  Future<void> setMaxWave(int value) async {
    if (value > maxWave) {
      await _prefs.setInt('maxWave', value);
    }
  }

  // --- Skin sélectionné ---
  String get selectedSkin => _prefs.getString('selectedSkin') ?? 'eclair';
  Future<void> setSelectedSkin(String skinId) async {
    await _prefs.setString('selectedSkin', skinId);
  }

  // --- Volume musique (0.0 → 1.0) ---
  double get musicVolume => _prefs.getDouble('musicVolume') ?? 0.35;
  Future<void> setMusicVolume(double value) async {
    await _prefs.setDouble('musicVolume', value);
  }

  // --- Volume SFX (0.0 → 1.0) ---
  double get sfxVolume => _prefs.getDouble('sfxVolume') ?? 0.6;
  Future<void> setSfxVolume(double value) async {
    await _prefs.setDouble('sfxVolume', value);
  }

  // --- Sensibilité joystick (0.5 → 2.0) ---
  double get joystickSensitivity =>
      _prefs.getDouble('joystickSensitivity') ?? 1.0;
  Future<void> setJoystickSensitivity(double value) async {
    await _prefs.setDouble('joystickSensitivity', value);
  }

  // --- Vibrations activées ---
  bool get vibrationsEnabled => _prefs.getBool('vibrationsEnabled') ?? true;
  Future<void> setVibrationsEnabled(bool value) async {
    await _prefs.setBool('vibrationsEnabled', value);
  }

  // --- Total kills (pour niveau/historique) ---
  int get totalKills => _prefs.getInt('totalKills') ?? 0;
  Future<void> addKills(int n) async {
    await _prefs.setInt('totalKills', totalKills + n);
  }

  // --- Parties jouées ---
  int get playCount => _prefs.getInt('playCount') ?? 0;
  Future<void> incrementPlayCount() async {
    await _prefs.setInt('playCount', playCount + 1);
  }

  // --- Reset des réglages ---
  Future<void> resetSettings() async {
    await _prefs.setDouble('musicVolume', 0.35);
    await _prefs.setDouble('sfxVolume', 0.6);
    await _prefs.setDouble('joystickSensitivity', 1.0);
    await _prefs.setBool('vibrationsEnabled', true);
  }
}
