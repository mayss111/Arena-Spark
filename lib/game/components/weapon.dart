import 'package:flutter/material.dart';

enum WeaponType {
  pistol,
  smg,
  ar,
  shotgun,
  sniper,
  tripleLaser,
  rocket,
}

class WeaponInfo {
  final WeaponType type;
  final String name;
  final String icon;
  final Color color;
  final double cooldown;
  final double damage;
  final double speed;
  final int magazineSize;
  final int pellets;
  final double spread;
  final int rarity;
  final String description;

  const WeaponInfo({
    required this.type,
    required this.name,
    required this.icon,
    required this.color,
    required this.cooldown,
    required this.damage,
    required this.speed,
    this.magazineSize = 30,
    this.pellets = 1,
    this.spread = 0.0,
    this.rarity = 1,
    this.description = '',
  });
}

const Map<WeaponType, WeaponInfo> weaponCatalog = {
  WeaponType.pistol: WeaponInfo(
    type: WeaponType.pistol,
    name: 'Pistolet Plasma',
    icon: '🔫',
    color: Color(0xFF41E0FF),
    cooldown: 0.35,
    damage: 1.0,
    speed: 450,
    magazineSize: 15,
    rarity: 1,
    description: 'Arme de base, équilibrée et fiable',
  ),
  WeaponType.smg: WeaponInfo(
    type: WeaponType.smg,
    name: 'MP40 Énergétique',
    icon: '⚡',
    color: Color(0xFFFFD700),
    cooldown: 0.10,
    damage: 0.6,
    speed: 480,
    magazineSize: 40,
    rarity: 2,
    description: 'Tir ultra-rapide, dégâts modérés',
  ),
  WeaponType.ar: WeaponInfo(
    type: WeaponType.ar,
    name: 'Fusil AK Cosmos',
    icon: '🎯',
    color: Color(0xFFFF6347),
    cooldown: 0.14,
    damage: 1.0,
    speed: 520,
    magazineSize: 30,
    rarity: 3,
    description: 'Fusil d\'assaut polyvalent',
  ),
  WeaponType.shotgun: WeaponInfo(
    type: WeaponType.shotgun,
    name: 'Super Canon M1887',
    icon: '💥',
    color: Color(0xFFFF69B4),
    cooldown: 0.7,
    damage: 0.7,
    speed: 420,
    magazineSize: 8,
    pellets: 5,
    spread: 0.35,
    rarity: 3,
    description: '5 projectiles en éventail, létal à courte portée',
  ),
  WeaponType.sniper: WeaponInfo(
    type: WeaponType.sniper,
    name: 'AWM Galactique',
    icon: '🦅',
    color: Color(0xFFAA44FF),
    cooldown: 1.2,
    damage: 3.0,
    speed: 700,
    magazineSize: 5,
    rarity: 4,
    description: 'Dégâts massifs à très longue portée',
  ),
  WeaponType.tripleLaser: WeaponInfo(
    type: WeaponType.tripleLaser,
    name: 'Laser Triple',
    icon: '✨',
    color: Color(0xFF00CED1),
    cooldown: 0.45,
    damage: 1.0,
    speed: 560,
    magazineSize: 25,
    pellets: 3,
    spread: 0.18,
    rarity: 4,
    description: '3 rayons lasers ciblés',
  ),
  WeaponType.rocket: WeaponInfo(
    type: WeaponType.rocket,
    name: 'Lance-Roquettes',
    icon: '🚀',
    color: Color(0xFFFF4500),
    cooldown: 1.5,
    damage: 2.5,
    speed: 380,
    magazineSize: 3,
    rarity: 5,
    description: 'Projectile explosif, zone d\'effet',
  ),
};
