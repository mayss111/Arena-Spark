import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/data/game_storage.dart';
import '../game/data/skin_data.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _titleController;
  late Animation<double> _glowAnim;
  late Animation<double> _titleAnim;

  GameStorage? _storage;
  int _highScore = 0;
  int _maxWave = 0;
  int _totalKills = 0;
  int _playCount = 0;
  int _playerLevel = 1;
  int _playerExp = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..forward();
    _glowAnim = CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);
    _titleAnim = CurvedAnimation(parent: _titleController, curve: Curves.easeOutBack);

    _loadStorage();
  }

  Future<void> _loadStorage() async {
    final s = await GameStorage.getInstance();
    final level = 1 + (s.totalKills ~/ 20);
    final exp = s.totalKills % 20;
    setState(() {
      _storage = s;
      _highScore = s.highScore;
      _maxWave = s.maxWave;
      _totalKills = s.totalKills;
      _playCount = s.playCount;
      _playerLevel = level;
      _playerExp = exp;
    });
  }

  @override
  void dispose() {
    _glowController.dispose();
    _particleController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070912),
      body: Stack(
        children: [
          _AnimatedBackground(controller: _particleController),
          _CornerDecorations(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      if (_storage != null) _buildPlayerProfile(),
                      const SizedBox(height: 24),
                      AnimatedBuilder(
                        animation: _titleAnim,
                        builder: (context, _) => Transform.scale(
                          scale: _titleAnim.value,
                          child: _buildLogo(_glowAnim.value),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSeasonBadge(),
                      const SizedBox(height: 24),
                      _buildQuickStats(),
                      const SizedBox(height: 28),
                      _MenuButton(
                        id: 'btn_play',
                        icon: '⚔️',
                        label: 'COMMENCER',
                        subLabel: 'Battle Royale',
                        gradient: const [
                          Color(0xFFFF6B35),
                          Color(0xFFF7931E),
                          Color(0xFFFFD700),
                        ],
                        onTap: () => Navigator.pushNamed(context, '/game'),
                        large: true,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _MenuButton(
                              id: 'btn_skins',
                              icon: '🎽',
                              label: 'SKINS',
                              gradient: const [
                                Color(0xFF7B68EE),
                                Color(0xFF4169E1),
                              ],
                              onTap: () async {
                                await Navigator.pushNamed(context, '/skins');
                                _loadStorage();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MenuButton(
                              id: 'btn_rank',
                              icon: '🏆',
                              label: 'CLASSEMENT',
                              gradient: const [
                                Color(0xFFFFD700),
                                Color(0xFFFF8C00),
                              ],
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🏆 Classement à venir !'),
                                    backgroundColor: Color(0xFFFF8C00),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MenuButton(
                              id: 'btn_settings',
                              icon: '⚙️',
                              label: 'RÉGLAGES',
                              gradient: const [
                                Color(0xFF9B59B6),
                                Color(0xFF673AB7),
                              ],
                              onTap: () =>
                                  Navigator.pushNamed(context, '/settings'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MenuButton(
                              id: 'btn_credits',
                              icon: '💎',
                              label: 'CRÉDITS',
                              gradient: const [
                                Color(0xFF00CED1),
                                Color(0xFF20B2AA),
                              ],
                              onTap: () =>
                                  Navigator.pushNamed(context, '/credits'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                      _buildNewsTicker(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerProfile() {
    final skin = getSkinById(_storage!.selectedSkin);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1033).withValues(alpha: 0.9),
            const Color(0xFF0A0E1A).withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF8A2BE2).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A2BE2).withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [skin.primaryColor, skin.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: skin.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(skin.emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'LVL $_playerLevel',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        skin.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      children: [
                        Container(color: Colors.white.withValues(alpha: 0.1)),
                        FractionallySizedBox(
                          widthFactor: _playerExp / 20,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFF6B35)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$_playerExp / 20 EXP',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo(double glow) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 220,
              height: 110,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.2,
                  colors: [
                    const Color(0xFFFF6B35).withValues(alpha: 0.25 + glow * 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF6B35),
                      Color(0xFFF7931E),
                      Color(0xFFFFD700),
                      Color(0xFFF7931E),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'SPARK',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 10,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color:
                              const Color(0xFFFF6B35).withValues(alpha: glow),
                          blurRadius: 24 + glow * 24,
                        ),
                        Shadow(
                          color:
                              const Color(0xFFFFD700).withValues(alpha: glow * 0.5),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF41E0FF), Color(0xFF8A2BE2)],
                    ).createShader(bounds),
                    child: const Text(
                      'A R E N A',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(20),
            color: const Color(0xFFFF6B35).withValues(alpha: 0.08),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⚡', style: TextStyle(fontSize: 12)),
              SizedBox(width: 6),
              Text(
                'BATTLE ROYALE  —  50 ENNEMIS  —  10 VAGUES',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(width: 6),
              Text('⚡', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7B68EE).withValues(alpha: 0.2),
            const Color(0xFF41E0FF).withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF41E0FF).withValues(alpha: 0.3),
        ),
      ),
      child: const Text(
        '✦ SAISON 1 : RÉVOLUTION COSMIQUE ✦',
        style: TextStyle(
          color: Color(0xFF41E0FF),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MiniStat(
              icon: '🏆',
              label: 'MEILLEUR',
              value: _formatK(_highScore),
              color: const Color(0xFFFFD700),
            ),
          ),
          _divider(),
          Expanded(
            child: _MiniStat(
              icon: '🌊',
              label: 'VAGUE MAX',
              value: '$_maxWave',
              color: const Color(0xFF41E0FF),
            ),
          ),
          _divider(),
          Expanded(
            child: _MiniStat(
              icon: '💥',
              label: 'KILLS',
              value: _formatK(_totalKills),
              color: const Color(0xFFFF6B6B),
            ),
          ),
          _divider(),
          Expanded(
            child: _MiniStat(
              icon: '🎮',
              label: 'PARTIES',
              value: '$_playCount',
              color: const Color(0xFF98FB98),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }

  Widget _buildNewsTicker() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFF41E0FF).withValues(alpha: 0.12),
            const Color(0xFF8A2BE2).withValues(alpha: 0.12),
            const Color(0xFFFF6B35).withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF41E0FF).withValues(alpha: 0.2),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.campaign, color: Color(0xFF41E0FF), size: 16),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '💡 Collectez des armes rares dans les zones ! Les loot rares pulsent violets sur la carte. Apprenez les touches 1-2 pour switcher !',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatK(int v) {
    if (v >= 10000) return '${(v / 1000).toStringAsFixed(1)}k';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return '$v';
  }
}

class _MiniStat extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _CornerDecorations extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6B35).withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8A2BE2).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            top: 120,
            right: 30,
            child: _DecoStar(size: 3, color: Color(0xFFFFD700)),
          ),
          const Positioned(
            top: 200,
            left: 50,
            child: _DecoStar(size: 2, color: Color(0xFF41E0FF)),
          ),
          const Positioned(
            bottom: 160,
            left: 30,
            child: _DecoStar(size: 2.5, color: Color(0xFFFF6B6B)),
          ),
        ],
      ),
    );
  }
}

class _DecoStar extends StatefulWidget {
  final double size;
  final Color color;
  const _DecoStar({required this.size, required this.color});

  @override
  State<_DecoStar> createState() => _DecoStarState();
}

class _DecoStarState extends State<_DecoStar> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: Duration(seconds: 2 + Random().nextInt(2)),
  )..repeat(reverse: true);
  late final _a = Tween(begin: 0.4, end: 1.0).animate(_c);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Opacity(
        opacity: _a.value,
        child: Icon(
          Icons.star,
          color: widget.color,
          size: 10 * widget.size,
        ),
      ),
    );
  }
}

class _MenuButton extends StatefulWidget {
  final String id;
  final String icon;
  final String label;
  final String? subLabel;
  final List<Color> gradient;
  final VoidCallback onTap;
  final bool large;
  const _MenuButton({
    required this.id,
    required this.icon,
    required this.label,
    this.subLabel,
    required this.gradient,
    required this.onTap,
    this.large = false,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
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
          height: widget.large ? 68 : 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.large ? 22 : 18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.first.withValues(alpha: _pressed ? 0 : 0.4),
                blurRadius: widget.large ? 24 : 16,
                spreadRadius: _pressed ? 0 : 2,
                offset: Offset(0, _pressed ? 0 : 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.large ? 21 : 17),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.25),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.icon,
                        style: TextStyle(fontSize: widget.large ? 26 : 22)),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.large ? 20 : 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: widget.large ? 2.5 : 1.5,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        if (widget.subLabel != null)
                          Text(
                            widget.subLabel!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBackground({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => CustomPaint(
        painter: _ParticlePainter(controller.value),
        size: MediaQuery.of(context).size,
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double t;
  static final List<_Particle> _particles =
      List.generate(45, (i) => _Particle(i));

  _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0.2, -0.4),
        radius: 1.6,
        colors: [
          Color(0xFF1A1033),
          Color(0xFF0F0A1E),
          Color(0xFF070912),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    for (final p in _particles) {
      final yPos = (p.startY - t * p.speed * size.height) % size.height;
      final xPos = (p.startX + sin((t + p.phase) * pi * 2) * 0.05) * size.width;
      final phaseFrac = ((t + p.phase) % 1);
      final alpha = sin(phaseFrac * pi) * 0.5 + 0.2;
      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha * p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(xPos, yPos), p.radius * (1 + sin(phaseFrac * pi * 2) * 0.3), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => true;
}

class _Particle {
  final double startX;
  final double startY;
  final double speed;
  final double radius;
  final double opacity;
  final double phase;
  final Color color;

  static const _palette = [
    Color(0xFF41E0FF),
    Color(0xFF8A2BE2),
    Color(0xFFFF6B35),
    Color(0xFFFFD700),
    Color(0xFF00CED1),
    Color(0xFFFF6B6B),
  ];

  _Particle(int seed)
      : startX = (seed * 47 % 100) / 100.0,
        startY = (seed * 83 % 100) / 100.0,
        speed = 0.03 + (seed % 8) * 0.012,
        radius = 0.8 + (seed % 6) * 0.55,
        opacity = 0.18 + (seed % 5) * 0.1,
        phase = (seed * 23 % 100) / 100.0,
        color = _palette[seed % _palette.length];
}
