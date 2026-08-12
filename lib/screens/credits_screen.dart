import 'package:flutter/material.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          key: const ValueKey('btn_back_credits'),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crédits',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('⚡', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF41E0FF), Color(0xFF7B68EE)],
              ).createShader(bounds),
              child: const Text(
                'SPARK ARENA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Version 1.0',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 40),
            const _CreditSection(
              title: '🎮 Développement',
              items: ['Flutter & Flame Engine'],
            ),
            const _CreditSection(
              title: '🎨 Design',
              items: ['Visuels procéduraux', 'Palette futuriste'],
            ),
            const _CreditSection(
              title: '🎵 Audio',
              items: ['Effets sonores intégrés'],
            ),
            const _CreditSection(
              title: '👾 Concept',
              items: [
                'Battle Royale pour enfants',
                'Inspiré de Free Fire',
                '100 % adapté aux jeunes joueurs',
              ],
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF41E0FF).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF41E0FF).withValues(alpha: 0.2)),
              ),
              child: const Column(
                children: [
                  Text('💡', style: TextStyle(fontSize: 28)),
                  SizedBox(height: 8),
                  Text(
                    'Spark Arena est un jeu sûr\npour les enfants.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pas de violence, pas de sang —\njuste de l\'action colorée et rigolote !',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _CreditSection extends StatelessWidget {
  final String title;
  final List<String> items;
  const _CreditSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                item,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, width: 60, color: Colors.white10),
        ],
      ),
    );
  }
}
