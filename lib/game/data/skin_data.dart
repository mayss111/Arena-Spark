import 'package:flutter/material.dart';

/// Données d'un skin (apparence du joueur).
class SkinData {
  final String id;
  final String name;
  final String emoji;
  final Color primaryColor;
  final Color secondaryColor;
  final int unlockScore; // Score cumulé nécessaire (0 = débloqué de base)

  const SkinData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.primaryColor,
    required this.secondaryColor,
    required this.unlockScore,
  });
}

/// Liste de tous les skins disponibles.
const List<SkinData> allSkins = [
  SkinData(
    id: 'eclair',
    name: 'Éclair',
    emoji: '⚡',
    primaryColor: Color(0xFF41E0FF),
    secondaryColor: Color(0xFF0A7ACA),
    unlockScore: 0, // Débloqué de base
  ),
  SkinData(
    id: 'flamme',
    name: 'Flamme',
    emoji: '🔥',
    primaryColor: Color(0xFFFF6347),
    secondaryColor: Color(0xFFCC3300),
    unlockScore: 500,
  ),
  SkinData(
    id: 'galaxie',
    name: 'Galaxie',
    emoji: '🌌',
    primaryColor: Color(0xFF9B59B6),
    secondaryColor: Color(0xFF6C3483),
    unlockScore: 1500,
  ),
  SkinData(
    id: 'nature',
    name: 'Nature',
    emoji: '🌿',
    primaryColor: Color(0xFF2ECC71),
    secondaryColor: Color(0xFF1A9850),
    unlockScore: 3000,
  ),
  SkinData(
    id: 'soleil',
    name: 'Soleil',
    emoji: '☀️',
    primaryColor: Color(0xFFFFD700),
    secondaryColor: Color(0xFFFF8C00),
    unlockScore: 5000,
  ),
  SkinData(
    id: 'arc_en_ciel',
    name: 'Arc-en-ciel',
    emoji: '🌈',
    primaryColor: Color(0xFFFF69B4),
    secondaryColor: Color(0xFF00CED1),
    unlockScore: 10000,
  ),
];

/// Retrouve un skin par son id.
SkinData getSkinById(String id) {
  return allSkins.firstWhere(
    (s) => s.id == id,
    orElse: () => allSkins.first,
  );
}
