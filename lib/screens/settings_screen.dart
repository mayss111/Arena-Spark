import 'package:flutter/material.dart';
import '../game/data/game_storage.dart';
import 'package:flame_audio/flame_audio.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  GameStorage? _storage;
  double _musicVolume = 0.35;
  double _sfxVolume = 0.6;
  double _joystickSensitivity = 1.0;
  bool _vibrations = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await GameStorage.getInstance();
    setState(() {
      _storage = s;
      _musicVolume = s.musicVolume;
      _sfxVolume = s.sfxVolume;
      _joystickSensitivity = s.joystickSensitivity;
      _vibrations = s.vibrationsEnabled;
    });
  }

  Future<void> _reset() async {
    if (_storage != null) {
      await _storage!.resetSettings();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey('btn_back_settings'),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Réglages',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            key: const ValueKey('btn_reset_settings'),
            onPressed: _reset,
            child: const Text('Réinitialiser',
                style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
      body: _storage == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const _SectionTitle('🎵 Audio'),
                _SettingSlider(
                  id: 'slider_music',
                  label: 'Volume musique',
                  icon: Icons.music_note,
                  value: _musicVolume,
                  min: 0,
                  max: 1,
                  divisions: 20,
                  displayValue: '${(_musicVolume * 100).round()}%',
                  onChanged: (v) async {
                    setState(() => _musicVolume = v);
                    await _storage!.setMusicVolume(v);
                    try {
                      FlameAudio.bgm.audioPlayer.setVolume(v);
                    } catch (_) {}
                  },
                ),
                const SizedBox(height: 16),
                _SettingSlider(
                  id: 'slider_sfx',
                  label: 'Volume effets sonores',
                  icon: Icons.surround_sound,
                  value: _sfxVolume,
                  min: 0,
                  max: 1,
                  divisions: 20,
                  displayValue: '${(_sfxVolume * 100).round()}%',
                  onChanged: (v) async {
                    setState(() => _sfxVolume = v);
                    await _storage!.setSfxVolume(v);
                  },
                ),
                const SizedBox(height: 32),
                const _SectionTitle('🕹️ Contrôles'),
                _SettingSlider(
                  id: 'slider_joystick',
                  label: 'Sensibilité joystick',
                  icon: Icons.gamepad,
                  value: _joystickSensitivity,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  displayValue: '${_joystickSensitivity.toStringAsFixed(1)}x',
                  onChanged: (v) async {
                    setState(() => _joystickSensitivity = v);
                    await _storage!.setJoystickSensitivity(v);
                  },
                ),
                const SizedBox(height: 32),
                const _SectionTitle('📱 Téléphone'),
                _SettingToggle(
                  id: 'toggle_vibrations',
                  label: 'Vibrations',
                  icon: Icons.vibration,
                  value: _vibrations,
                  onChanged: (v) async {
                    setState(() => _vibrations = v);
                    await _storage!.setVibrationsEnabled(v);
                  },
                ),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white60,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _SettingSlider extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  const _SettingSlider({
    required this.id,
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF41E0FF), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(color: Colors.white, fontSize: 15)),
              ),
              Text(displayValue,
                  style: const TextStyle(
                      color: Color(0xFF41E0FF),
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF41E0FF),
              inactiveTrackColor: Colors.white12,
              thumbColor: const Color(0xFF41E0FF),
              overlayColor: const Color(0xFF41E0FF).withValues(alpha: 0.15),
              trackHeight: 3,
            ),
            child: Slider(
              key: ValueKey(id),
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingToggle extends StatelessWidget {
  final String id;
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingToggle({
    required this.id,
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF9B59B6), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 15)),
          ),
          Switch(
            key: ValueKey(id),
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF9B59B6),
          ),
        ],
      ),
    );
  }
}
