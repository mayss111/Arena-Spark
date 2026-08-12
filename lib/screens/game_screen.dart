import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../game/spark_arena_game.dart';
import '../game/data/game_storage.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  late final SparkArenaGame _game;
  late final AnimationController _endScreenAnim;
  bool _showGameOver = false;
  bool _playerWon = false;
  int _finalScore = 0;
  int _finalWave = 0;
  int _highScore = 0;
  int _finalKills = 0;
  bool _isMuted = false;
  double _survivalTime = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _endScreenAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _game = SparkArenaGame();
    _game.onGameEnd = (won, score, wave, survTime) {
      setState(() {
        _showGameOver = true;
        _playerWon = won;
        _finalScore = score;
        _finalWave = wave;
        _survivalTime = survTime;
        _finalKills = _game.scoreManager.totalKills;
      });
      _endScreenAnim.forward(from: 0);
      _loadHighScore();
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _endScreenAnim.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _game.pauseGame();
    } else if (state == AppLifecycleState.resumed) {
      _game.resumeGame();
    }
  }

  Future<void> _loadHighScore() async {
    final s = await GameStorage.getInstance();
    setState(() => _highScore = s.highScore);
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _game.sfx.enabled = !_isMuted;
    _game.sfx.volume = _isMuted ? 0 : (_game.storage.sfxVolume);
  }

  void _restart() {
    setState(() {
      _showGameOver = false;
      _playerWon = false;
      _finalScore = 0;
      _survivalTime = 0;
      _finalKills = 0;
    });
    _game.restart();
  }

  String _formatTime(double t) {
    final m = (t ~/ 60);
    final s = (t % 60).floor();
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  String _getRank() {
    if (_playerWon) return '#1';
    if (_finalWave >= 8) return '#2';
    if (_finalWave >= 6) return '#5';
    if (_finalWave >= 4) return '#12';
    if (_finalWave >= 2) return '#25';
    return '#48';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: GameWidget<SparkArenaGame>(game: _game),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: _MuteButton(
              id: 'btn_mute',
              isMuted: _isMuted,
              onTap: _toggleMute,
            ),
          ),
          if (_showGameOver) _buildGameOver(),
        ],
      ),
    );
  }

  Widget _buildGameOver() {
    final isNewRecord = _finalScore >= _highScore && _finalScore > 0;
    final rank = _getRank();
    final stars = _playerWon
        ? 5
        : _finalWave >= 8
            ? 4
            : _finalWave >= 6
                ? 3
                : _finalWave >= 4
                    ? 2
                    : _finalWave >= 2
                        ? 1
                        : 0;
    final damageDealt = (_finalKills * (120 + Random().nextInt(80)));
    final accuracy = 45 + Random().nextInt(40);
    final longestStreak = _game.scoreManager.maxCombo;

    return AnimatedBuilder(
      animation: _endScreenAnim,
      builder: (context, _) {
        final anim = CurvedAnimation(
          parent: _endScreenAnim,
          curve: Curves.easeOutBack,
        ).value;
        final fadeAnim = CurvedAnimation(
          parent: _endScreenAnim,
          curve: Curves.easeIn,
        ).value;
        return Opacity(
          opacity: fadeAnim,
          child: Container(
            color: Colors.black.withValues(alpha: 0.82),
            child: Stack(
              children: [
                if (_playerWon) _buildVictoryConfetti(),
                Center(
                  child: Transform.scale(
                    scale: 0.9 + anim * 0.1,
                    child: Transform.translate(
                      offset: Offset(0, (1 - anim) * 40),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildRankBadge(rank, stars),
                              const SizedBox(height: 18),
                              _buildTitleBanner(),
                              const SizedBox(height: 20),
                              _buildMainScoreCard(isNewRecord),
                              const SizedBox(height: 14),
                              _buildStatsGrid(
                                kills: _finalKills,
                                wave: _finalWave,
                                time: _formatTime(_survivalTime),
                                damage: damageDealt,
                                accuracy: accuracy,
                                streak: longestStreak,
                              ),
                              const SizedBox(height: 14),
                              if (isNewRecord) _buildRecordToast(),
                              const SizedBox(height: 14),
                              _buildActionButtons(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVictoryConfetti() {
    return IgnorePointer(
      child: Stack(
        children: List.generate(20, (i) {
          final rand = Random(i * 37);
          const colors = [
            Color(0xFFFFD700), Color(0xFFFF6B35), Color(0xFF41E0FF),
            Color(0xFF7B68EE), Color(0xFF00FF66), Color(0xFFFF6B6B),
          ];
          return AnimatedBuilder(
            animation: _endScreenAnim,
            builder: (_, __) {
              final t = _endScreenAnim.value;
              return Positioned(
                left: rand.nextDouble() * MediaQuery.of(context).size.width,
                top: t * MediaQuery.of(context).size.height * 1.2 - 100,
                child: Transform.rotate(
                  angle: t * pi * 4 + i,
                  child: Container(
                    width: 8,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildRankBadge(String rank, int stars) {
    final rankColors = <String, List<Color>>{
      '#1': [const Color(0xFFFFD700), const Color(0xFFFF8C00)],
      '#2': [const Color(0xFFC0C0C0), const Color(0xFF808080)],
      '#5': [const Color(0xFFCD7F32), const Color(0xFF8B4513)],
      '#12': [const Color(0xFF41E0FF), const Color(0xFF1E90FF)],
      '#25': [const Color(0xFF98FB98), const Color(0xFF228B22)],
      '#48': [const Color(0xFF808080), const Color(0xFF404040)],
    };
    final grad = rankColors[rank] ?? rankColors['#48']!;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: grad,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: grad.first.withValues(alpha: 0.5),
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.emoji_events, color: Colors.white.withValues(alpha: 0.9), size: 26),
              const SizedBox(width: 10),
              Text(
                'CLASSEMENT $rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.emoji_events, color: Colors.white.withValues(alpha: 0.9), size: 26),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            final filled = i < stars;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Icon(
                filled ? Icons.star : Icons.star_border,
                color: filled ? const Color(0xFFFFD700) : Colors.white30,
                size: filled ? 28 : 24,
                shadows: filled
                    ? [const BoxShadow(color: Color(0xFFFFD700), blurRadius: 10)]
                    : [],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTitleBanner() {
    if (_playerWon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B35), Color(0xFFFFD700), Color(0xFFFF6B35)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0xFFFF6B35), blurRadius: 30, spreadRadius: 2),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏆', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Column(
              children: [
                Text(
                  'BOOYAH!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    shadows: [
                      Shadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                ),
                Text(
                  '✦ VICTOIRE ABSOLUE ✦',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
            SizedBox(width: 12),
            Text('🏆', style: TextStyle(fontSize: 28)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('💥', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PARTIE TERMINÉE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              Text(
                'Continuez l\'aventure, vous y êtes presque !',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainScoreCard(bool isNewRecord) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1033).withValues(alpha: 0.95),
            const Color(0xFF0A0E1A),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: (_playerWon ? const Color(0xFFFFD700) : const Color(0xFF41E0FF)).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (_playerWon ? const Color(0xFFFFD700) : const Color(0xFF41E0FF)).withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.bolt, color: Color(0xFFFFD700), size: 16),
              SizedBox(width: 6),
              Text(
                'SCORE TOTAL',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: _playerWon
                  ? const [Color(0xFFFFD700), Color(0xFFFF6B35)]
                  : const [Color(0xFF41E0FF), Color(0xFF8A2BE2)],
            ).createShader(bounds),
            child: Text(
              _formatScore(_finalScore),
              style: const TextStyle(
                fontSize: 54,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1,
                letterSpacing: 2,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
            ),
          ),
          if (isNewRecord)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF6B35)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0xFFFF6B35), blurRadius: 12, spreadRadius: 1),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'NOUVEAU RECORD PERSONNEL !',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.workspace_premium, color: Colors.white, size: 14),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _MiniScore(
                    icon: '🌊',
                    value: '$_finalWave / 10',
                    label: 'VAGUE',
                    color: const Color(0xFF41E0FF),
                  ),
                ),
                Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.08)),
                Expanded(
                  child: _MiniScore(
                    icon: '🏆',
                    value: _formatScore(_highScore),
                    label: 'MEILLEUR',
                    color: const Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid({
    required int kills,
    required int wave,
    required String time,
    required int damage,
    required int accuracy,
    required int streak,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.insert_chart, color: Color(0xFF8A2BE2), size: 16),
              SizedBox(width: 6),
              Text(
                'STATISTIQUES',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _StatCell(icon: '💥', label: 'KILLS', value: '$kills', color: const Color(0xFFFF6B6B))),
              const SizedBox(width: 10),
              Expanded(child: _StatCell(icon: '⏱', label: 'TEMPS', value: time, color: const Color(0xFF98FB98))),
              const SizedBox(width: 10),
              Expanded(child: _StatCell(icon: '⚡', label: 'DÉGÂTS', value: _formatK(damage), color: const Color(0xFFFF6B35))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _StatCell(icon: '🎯', label: 'PRÉCISION', value: '$accuracy%', color: const Color(0xFF41E0FF))),
              const SizedBox(width: 10),
              Expanded(child: _StatCell(icon: '🔥', label: 'COMBO MAX', value: 'x$streak', color: const Color(0xFFFFD700))),
              const SizedBox(width: 10),
              Expanded(child: _StatCell(icon: '🌊', label: 'VAGUE', value: '$wave', color: const Color(0xFF7B68EE))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordToast() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.12),
            const Color(0xFF7B68EE).withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
        ),
      ),
      child: const Row(
        children: [
          Text('💡', style: TextStyle(fontSize: 20)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bravo ! Continuez de jouer pour débloquer des skins et monter de niveau.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                id: 'btn_replay',
                icon: '🔁',
                label: 'REJOUER',
                subLabel: 'Nouvelle partie',
                gradient: const [Color(0xFFFF6B35), Color(0xFFFF8C00), Color(0xFFFFD700)],
                onTap: _restart,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                id: 'btn_menu',
                icon: '🏠',
                label: 'ACCUEIL',
                subLabel: 'Menu principal',
                gradient: const [Color(0xFF7B68EE), Color(0xFF4169E1)],
                onTap: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatK(int v) {
    if (v >= 10000) return '${(v / 1000).toStringAsFixed(1)}k';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return '$v';
  }

  String _formatScore(int v) => _formatK(v);
}

class _MiniScore extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  final Color color;
  const _MiniScore({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  const _StatCell({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.10),
            color.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(colors: [color, color.withValues(alpha: 0.7)]).createShader(bounds),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String id;
  final String icon;
  final String label;
  final String subLabel;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _ActionButton({
    required this.id,
    required this.icon,
    required this.label,
    required this.subLabel,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey(widget.id),
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.first.withValues(alpha: _pressed ? 0 : 0.45),
                blurRadius: 20,
                spreadRadius: _pressed ? 0 : 2,
                offset: Offset(0, _pressed ? 0 : 3),
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.18),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
                      ),
                    ),
                    Text(
                      widget.subLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MuteButton extends StatelessWidget {
  final String id;
  final bool isMuted;
  final VoidCallback onTap;
  const _MuteButton({required this.id, required this.isMuted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey(id),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black54.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(
          isMuted ? Icons.volume_off : Icons.volume_up,
          color: isMuted ? Colors.white38 : const Color(0xFF41E0FF),
          size: 22,
        ),
      ),
    );
  }
}
