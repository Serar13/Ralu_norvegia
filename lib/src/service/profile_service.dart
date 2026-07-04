import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/family_profile.dart';

class ProfileService {
  static final _db = FirebaseFirestore.instance;
  static const _activeProfileKey = 'activeProfileId';
  static const _activeProfileNameKey = 'activeProfileName';
  static const _activeProfileEmojiKey = 'activeProfileEmoji';
  static const _activeProfileIsAdminKey = 'activeProfileIsAdmin';

  // ──────────────────────────────────────────────
  //  PIN hashing (simple SHA-256)
  // ──────────────────────────────────────────────
  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  // ──────────────────────────────────────────────
  //  CRUD
  // ──────────────────────────────────────────────

  /// Creates a new family profile under the user's doc.
  static Future<String> createProfile({
    required String uid,
    required String name,
    required String emoji,
    required int colorValue,
    required bool isAdmin,
    String? pin,
    int? order,
  }) async {
    final profilesRef = _db.collection('users').doc(uid).collection('familyProfiles');

    // Determine order
    final existing = await profilesRef.orderBy('order', descending: true).limit(1).get();
    final nextOrder = order ?? ((existing.docs.isNotEmpty ? (existing.docs.first.data()['order'] ?? 0) : -1) + 1);

    final profile = FamilyProfile(
      id: '', // will be set by Firestore
      name: name,
      emoji: emoji,
      color: Color(colorValue),
      isAdmin: isAdmin,
      pinHash: (isAdmin && pin != null) ? _hashPin(pin) : null,
      order: nextOrder,
    );

    final docRef = await profilesRef.add(profile.toFirestore());
    return docRef.id;
  }

  /// Returns a stream of all family profiles for the user.
  static Stream<List<FamilyProfile>> getProfilesStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('familyProfiles')
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map((d) => FamilyProfile.fromFirestore(d)).toList());
  }

  /// Returns all profiles once (non-streaming).
  static Future<List<FamilyProfile>> getProfiles(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('familyProfiles')
        .orderBy('order')
        .get();
    return snap.docs.map((d) => FamilyProfile.fromFirestore(d)).toList();
  }

  /// Deletes a profile.
  static Future<void> deleteProfile(String uid, String profileId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('familyProfiles')
        .doc(profileId)
        .delete();
  }

  /// Updates a profile.
  static Future<void> updateProfile({
    required String uid,
    required String profileId,
    String? name,
    String? emoji,
    int? colorValue,
    bool? isAdmin,
    String? newPin,
  }) async {
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (emoji != null) updates['emoji'] = emoji;
    if (colorValue != null) updates['color'] = colorValue;
    if (isAdmin != null) {
      updates['isAdmin'] = isAdmin;
      if (!isAdmin) {
        updates['pinHash'] = FieldValue.delete();
      }
    }
    if (newPin != null) updates['pinHash'] = _hashPin(newPin);

    if (updates.isNotEmpty) {
      await _db
          .collection('users')
          .doc(uid)
          .collection('familyProfiles')
          .doc(profileId)
          .update(updates);
    }
  }

  // ──────────────────────────────────────────────
  //  PIN verification
  // ──────────────────────────────────────────────

  /// Verifies the admin PIN. Returns true if correct.
  static Future<bool> verifyAdminPin(String uid, String profileId, String pin) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('familyProfiles')
        .doc(profileId)
        .get();

    if (!doc.exists) return false;
    final storedHash = doc.data()?['pinHash'] as String?;
    if (storedHash == null) return false;

    return storedHash == _hashPin(pin);
  }

  // ──────────────────────────────────────────────
  //  Active profile (SharedPreferences)
  // ──────────────────────────────────────────────

  /// Sets the currently active profile locally.
  static Future<void> setActiveProfile(FamilyProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeProfileKey, profile.id);
    await prefs.setString(_activeProfileNameKey, profile.name);
    await prefs.setString(_activeProfileEmojiKey, profile.emoji);
    await prefs.setBool(_activeProfileIsAdminKey, profile.isAdmin);
  }

  /// Gets the active profile ID (or null if none selected).
  static Future<String?> getActiveProfileId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeProfileKey);
  }

  /// Gets the active profile name.
  static Future<String?> getActiveProfileName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeProfileNameKey);
  }

  /// Gets the active profile emoji.
  static Future<String?> getActiveProfileEmoji() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeProfileEmojiKey);
  }

  /// Returns true if the active profile is admin.
  static Future<bool> isActiveProfileAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_activeProfileIsAdminKey) ?? false;
  }

  /// Clears active profile (on logout or profile switch).
  static Future<void> clearActiveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeProfileKey);
    await prefs.remove(_activeProfileNameKey);
    await prefs.remove(_activeProfileEmojiKey);
    await prefs.remove(_activeProfileIsAdminKey);
  }

  // ──────────────────────────────────────────────
  //  Task delegation
  // ──────────────────────────────────────────────

  /// Delegates a task to a family member's profile.
  static Future<void> delegateTask({
    required String uid,
    required String targetProfileId,
    required String week,
    required String day,
    required int locationIndex,
    required int taskIndex,
    required String taskName,
    required String delegatedByProfileId,
  }) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('familyProfiles')
        .doc(targetProfileId)
        .collection('delegatedTasks')
        .add({
      'week': week,
      'day': day,
      'locationIndex': locationIndex,
      'taskIndex': taskIndex,
      'taskName': taskName,
      'delegatedBy': delegatedByProfileId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns stream of delegated tasks for a profile.
  static Stream<QuerySnapshot> getDelegatedTasksStream(String uid, String profileId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('familyProfiles')
        .doc(profileId)
        .collection('delegatedTasks')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Marks a delegated task as done.
  static Future<void> markDelegatedTaskDone(String uid, String profileId, String taskDocId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('familyProfiles')
        .doc(profileId)
        .collection('delegatedTasks')
        .doc(taskDocId)
        .update({'status': 'done'});
  }

  /// Marks a delegated task as pending again.
  static Future<void> markDelegatedTaskPending(String uid, String profileId, String taskDocId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('familyProfiles')
        .doc(profileId)
        .collection('delegatedTasks')
        .doc(taskDocId)
        .update({'status': 'pending'});
  }

  /// Checks if profiles have been created for this user.
  static Future<bool> hasProfiles(String uid) async {
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('familyProfiles')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Ensures that at least one admin profile exists for the user.
  /// If none exists, creates a default admin profile named "Mama" with "👩" emoji.
  /// Also heals any existing admin profile that has a null or empty PIN hash.
  static Future<void> ensureAdminProfileExists(String uid) async {
    final profiles = await getProfiles(uid);

    // Heal existing admin profiles with null/empty PIN hashes
    String? firstValidAdminPinHash;
    for (final p in profiles) {
      if (p.isAdmin && p.pinHash != null && p.pinHash!.isNotEmpty) {
        firstValidAdminPinHash = p.pinHash;
        break;
      }
    }

    // Default fallback to hashed "0000" if no admin profile has a PIN hash
    firstValidAdminPinHash ??= _hashPin('0000');

    for (final p in profiles) {
      if (p.isAdmin && (p.pinHash == null || p.pinHash!.isEmpty)) {
        await _db
            .collection('users')
            .doc(uid)
            .collection('familyProfiles')
            .doc(p.id)
            .update({'pinHash': firstValidAdminPinHash});
      }
    }

    final hasAdmin = profiles.any((p) => p.isAdmin);
    if (!hasAdmin) {
      await createProfile(
        uid: uid,
        name: 'Mama',
        emoji: '👩',
        colorValue: 0xFF6B8F71, // default green accent
        isAdmin: true,
        pin: '0000', // default PIN
      );
    }
  }
}
