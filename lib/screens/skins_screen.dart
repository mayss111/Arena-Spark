import 'package:flutter/material.dart';
import '../game/data/skin_data.dart';
import '../game/data/game_storage.dart';

class SkinsScreen extends StatefulWidget {
  const SkinsScreen({super.key});

  @override
  State<SkinsScreen> createState() => _SkinsScreenState();
}

class _SkinsScreenState extends State<SkinsScreen> {
  GameStorage? _storage;
  String _selectedSkinId = 'eclair';
  int _totalScore = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await GameStorage.getInstance();
    setState(() {
      _storage = s;
      _selectedSkinId = s.selectedSkin;
      _totalScore = s.totalScore;
    });
  }

  bool _isUnlocked(SkinData skin) => _totalScore >= skin.unlockScore;

  Future<void> _selectSkin(SkinData skin) async {
    if (!_isUnlocked(skin)) return;
    setState(() => _selectedSkinId = skin.id);
    await _storage?.setSelectedSkin(skin.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey('btn_back_skins'),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Skins',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$_totalScore pts',
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _storage == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Text(
                    'Gagne des points pour débloquer de nouveaux skins !',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: allSkins.length,
                    itemBuilder: (context, i) {
                      final skin = allSkins[i];
                      final unlocked = _isUnlocked(skin);
                      final selected = _selectedSkinId == skin.id;
                      return _SkinCard(
                        skin: skin,
                        unlocked: unlocked,
                        selected: selected,
                        onTap: () => _selectSkin(skin),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _SkinCard extends StatefulWidget {
  final SkinData skin;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;

  const _SkinCard({
    required this.skin,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SkinCard> createState() => _SkinCardState();
}

class _SkinCardState extends State<_SkinCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glow = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('skin_${widget.skin.id}'),
      onTap: widget.unlocked ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _glow,
        builder: (context, _) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: widget.unlocked
                  ? widget.skin.primaryColor.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.selected
                    ? const Color(0xFFFFD700)
                    : widget.unlocked
                        ? widget.skin.primaryColor.withValues(alpha: 0.4)
                        : Colors.white12,
                width: widget.selected ? 2.5 : 1.5,
              ),
              boxShadow: widget.selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700)
                            .withValues(alpha: 0.2 + _glow.value * 0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Preview du skin
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (widget.unlocked)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: widget.skin.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: widget.skin.primaryColor
                                  .withValues(alpha: 0.3 + _glow.value * 0.3),
                              blurRadius: 16,
                              spreadRadius: 3,
                            )
                          ],
                        ),
                      )
                    else
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lock,
                            color: Colors.white30, size: 28),
                      ),
                    if (widget.selected)
                      const Positioned(
                        top: -4,
                        right: -4,
                        child: Text('✓', style: TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(widget.skin.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(
                  widget.skin.name,
                  style: TextStyle(
                    color: widget.unlocked ? Colors.white : Colors.white30,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                if (!widget.unlocked)
                  Text(
                    '${widget.skin.unlockScore} pts',
                    style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11),
                  )
                else
                  Text(
                    widget.selected ? 'Sélectionné' : 'Débloqué',
                    style: TextStyle(
                      color: widget.selected
                          ? const Color(0xFFFFD700)
                          : Colors.white38,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
