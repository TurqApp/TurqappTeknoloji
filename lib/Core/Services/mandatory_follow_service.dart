import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';

class MandatoryFollowService {
  MandatoryFollowService._();
  static final MandatoryFollowService instance = MandatoryFollowService._();

  static const String _primaryDocId = 'forceFollow';
  Future<void>? _inFlight;

  Future<void> enforceForCurrentUser() async {
    final existing = _inFlight;
    if (existing != null) return existing;
    final future = _enforceInternal();
    _inFlight = future;
    try {
      await future;
    } finally {
      _inFlight = null;
    }
  }

  Future<void> _enforceInternal() async {
    final me = FirebaseAuth.instance.currentUser?.uid;
    if (me == null || me.isEmpty) return;

    final required = await _loadRequiredUids();
    if (required.isEmpty) return;

    for (final uid in required) {
      if (uid == me) continue;
      try {
        await FollowService.ensureFollowing(uid, bypassDailyLimit: true);
      } catch (e) {
        // Transaction/rule edge-case durumlarında takip ilişkisini yine de kur.
        try {
          await _fallbackEnsureFollowing(me: me, other: uid);
        } catch (fallbackError) {
          // Sessiz yutmak yerine logla; kullanıcı akışını bloklamasın.
          // ignore: avoid_print
          print(
              '[MandatoryFollow] follow failed uid=$uid error=$e fallback=$fallbackError');
        }
      }
    }
  }

  Future<List<String>> _loadRequiredUids() async {
    final data = await ConfigRepository.ensure().getAdminConfigDoc(
      _primaryDocId,
      preferCache: true,
      ttl: const Duration(hours: 1),
    );
    final parsed = _parseRequiredFrom(data);
    return parsed;
  }

  List<String> _parseRequiredFrom(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return const [];

    final enabled = data['enabled'];
    if (enabled is bool && enabled == false) return const [];

    final out = <String>{};

    void addIfValid(dynamic v) {
      if (v is String) {
        final trimmed = v.trim();
        if (trimmed.isNotEmpty) out.add(trimmed);
      }
    }

    void addArray(dynamic arr) {
      if (arr is List) {
        for (final v in arr) {
          addIfValid(v);
        }
      }
    }

    addIfValid(data['requiredUserIds']); // tek string girilmişse de destekle
    addArray(data['requiredUserIds']);
    addIfValid(data['equiredUserIds']); // olası yazım hatası toleransı
    addArray(data['equiredUserIds']);
    addIfValid(data['requiredUserId']);
    addIfValid(data['uid']);
    addIfValid(data['userId']);

    return out.toList(growable: false);
  }

  Future<void> _fallbackEnsureFollowing({
    required String me,
    required String other,
  }) async {
    if (me == other) return;
    final db = FirebaseFirestore.instance;
    final now = DateTime.now().millisecondsSinceEpoch;

    final myFollowingRef =
        db.collection('users').doc(me).collection('followings').doc(other);
    final otherFollowersRef =
        db.collection('users').doc(other).collection('followers').doc(me);

    final batch = db.batch();
    batch.set(myFollowingRef, {'timeStamp': now}, SetOptions(merge: true));
    batch.set(otherFollowersRef, {'timeStamp': now}, SetOptions(merge: true));
    await batch.commit();
  }
}
