import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyProfile {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final bool isAdmin;
  final String? pinHash; // simple hash for admin PIN
  final int order;
  final DateTime? createdAt;

  const FamilyProfile({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    this.isAdmin = false,
    this.pinHash,
    this.order = 0,
    this.createdAt,
  });

  /// Predefined emoji options for profile creation
  static const List<String> availableEmojis = [
    '👩', '👨', '👦', '👧', '👶', '🧑', '👴', '👵',
    '🐱', '🐶', '🦊', '🐻', '🌟', '🌈', '🏠', '🧹',
  ];

  /// Predefined color options (pastel tones matching the app theme)
  static const List<Color> availableColors = [
    Color(0xFF6B8F71), // forest green (accent3)
    Color(0xFFA8D5BA), // mint (primary)
    Color(0xFF7BAFB0), // teal
    Color(0xFFE8A87C), // peach
    Color(0xFFD4A5A5), // rose
    Color(0xFF9CADCE), // periwinkle
    Color(0xFFB8B5FF), // lavender
    Color(0xFFFFD3B6), // apricot
  ];

  factory FamilyProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FamilyProfile(
      id: doc.id,
      name: data['name'] ?? '',
      emoji: data['emoji'] ?? '🧑',
      color: Color(data['color'] ?? 0xFF6B8F71),
      isAdmin: data['isAdmin'] ?? false,
      pinHash: data['pinHash'],
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'emoji': emoji,
      'color': color.value,
      'isAdmin': isAdmin,
      if (pinHash != null) 'pinHash': pinHash,
      'order': order,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  FamilyProfile copyWith({
    String? id,
    String? name,
    String? emoji,
    Color? color,
    bool? isAdmin,
    String? pinHash,
    int? order,
  }) {
    return FamilyProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      isAdmin: isAdmin ?? this.isAdmin,
      pinHash: pinHash ?? this.pinHash,
      order: order ?? this.order,
      createdAt: createdAt,
    );
  }
}
