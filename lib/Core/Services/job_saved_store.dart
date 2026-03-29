import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedJobRecord {
  final String jobId;
  final int timeStamp;

  const SavedJobRecord({
    required this.jobId,
    required this.timeStamp,
  });
}

class JobSavedStore {
  JobSavedStore._();
  static JobSavedStore? _instance;
  static JobSavedStore? maybeFind() => _instance;

  static JobSavedStore ensure() =>
      maybeFind() ?? (_instance = JobSavedStore._());

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _prefsPrefix = 'job_saved_store_v1:';
  static SharedPreferences? _prefs;

  static CollectionReference<Map<String, dynamic>> _userSavedJobs(String uid) {
    return _firestore.collection('users').doc(uid).collection('savedJobs');
  }

  static DocumentReference<Map<String, dynamic>> _savedJobDoc(
    String uid,
    String jobId,
  ) {
    return _userSavedJobs(uid).doc(jobId);
  }

  static DocumentReference<Map<String, dynamic>> _legacySavedJobDoc(
    String uid,
    String jobId,
  ) {
    return _firestore.collection('SavedIsBul').doc('${uid}_$jobId');
  }

  static Map<String, dynamic> _payload(
      String uid, String jobId, int timeStamp) {
    return <String, dynamic>{
      'userID': uid,
      'jobID': jobId,
      'timeStamp': timeStamp,
    };
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
      final parsedNum = num.tryParse(value.trim());
      if (parsedNum != null) return parsedNum.toInt();
    }
    return fallback;
  }

  static String _asTrimmedString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static Future<bool> isSaved(String uid, String jobId) async {
    DocumentSnapshot<Map<String, dynamic>> currentSnap;
    try {
      currentSnap = await _savedJobDoc(uid, jobId).get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return false;
      }
      rethrow;
    }
    if (currentSnap.exists) return true;

    DocumentSnapshot<Map<String, dynamic>> legacySnap;
    try {
      legacySnap = await _legacySavedJobDoc(uid, jobId).get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return false;
      }
      rethrow;
    }
    if (!legacySnap.exists) return false;

    final legacyData = legacySnap.data() ?? const <String, dynamic>{};
    final timeStamp = _asInt(
      legacyData['timeStamp'],
      fallback: DateTime.now().millisecondsSinceEpoch,
    );
    await _migrateLegacyDoc(uid, jobId, timeStamp);
    return true;
  }

  static Future<void> save(String uid, String jobId) async {
    final timeStamp = DateTime.now().millisecondsSinceEpoch;
    final batch = _firestore.batch();
    batch.set(_savedJobDoc(uid, jobId), _payload(uid, jobId, timeStamp));
    batch.delete(_legacySavedJobDoc(uid, jobId));
    await batch.commit();
    await _invalidateCache(uid);
  }

  static Future<void> unsave(String uid, String jobId) async {
    final batch = _firestore.batch();
    batch.delete(_savedJobDoc(uid, jobId));
    batch.delete(_legacySavedJobDoc(uid, jobId));
    await batch.commit();
    await _invalidateCache(uid);
  }

  static Future<List<SavedJobRecord>> getSavedJobs(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return const <SavedJobRecord>[];
    if (!forceRefresh && preferCache) {
      final cached = await _readCache(normalizedUid);
      if (cached != null) return cached;
    }
    if (cacheOnly) return const <SavedJobRecord>[];

    QuerySnapshot<Map<String, dynamic>> currentSnap;
    QuerySnapshot<Map<String, dynamic>> legacySnap;
    try {
      currentSnap = await _userSavedJobs(normalizedUid)
          .orderBy('timeStamp', descending: true)
          .get();
      legacySnap = await _firestore
          .collection('SavedIsBul')
          .where('userID', isEqualTo: normalizedUid)
          .get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return const <SavedJobRecord>[];
      }
      rethrow;
    }

    final byJobId = <String, SavedJobRecord>{};
    for (final doc in currentSnap.docs) {
      final data = doc.data();
      final jobId = _asTrimmedString(data['jobID']) == ''
          ? _asTrimmedString(doc.id)
          : _asTrimmedString(data['jobID']);
      if (jobId.isEmpty) continue;
      byJobId[jobId] = SavedJobRecord(
        jobId: jobId,
        timeStamp: _asInt(data['timeStamp']),
      );
    }

    if (legacySnap.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in legacySnap.docs) {
        final data = doc.data();
        final jobId = _asTrimmedString(data['jobID']);
        if (jobId.isEmpty) continue;
        final timeStamp = _asInt(
          data['timeStamp'],
          fallback: DateTime.now().millisecondsSinceEpoch,
        );
        final existing = byJobId[jobId];
        if (existing == null || timeStamp > existing.timeStamp) {
          byJobId[jobId] = SavedJobRecord(jobId: jobId, timeStamp: timeStamp);
        }
        batch.set(
          _savedJobDoc(normalizedUid, jobId),
          _payload(normalizedUid, jobId, timeStamp),
        );
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    final items = byJobId.values.toList()
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    await _storeCache(normalizedUid, items);
    return items;
  }

  static Future<void> removeSavedJobs(String uid, List<String> jobIds) async {
    if (jobIds.isEmpty) return;
    final batch = _firestore.batch();
    for (final jobId in jobIds) {
      batch.delete(_savedJobDoc(uid, jobId));
      batch.delete(_legacySavedJobDoc(uid, jobId));
    }
    await batch.commit();
    await _invalidateCache(uid);
  }

  static Future<void> _migrateLegacyDoc(
    String uid,
    String jobId,
    int timeStamp,
  ) async {
    final batch = _firestore.batch();
    batch.set(_savedJobDoc(uid, jobId), _payload(uid, jobId, timeStamp));
    batch.delete(_legacySavedJobDoc(uid, jobId));
    await batch.commit();
    await _invalidateCache(uid);
  }

  static Future<List<SavedJobRecord>?> _readCache(String uid) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = '$_prefsPrefix$uid';
    final raw = prefs?.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedRaw = jsonDecode(raw);
      if (decodedRaw is! Map) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final decoded = Map<String, dynamic>.from(
        decodedRaw.cast<dynamic, dynamic>(),
      );
      final savedAt = _asInt(decoded['savedAt']);
      if (savedAt <= 0) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(savedAt);
      if (DateTime.now().difference(cachedAt) > const Duration(hours: 12)) {
        await prefs?.remove(prefsKey);
        return null;
      }
      var shouldPrune = false;
      final items = <SavedJobRecord>[];
      for (final rawItem
          in (decoded['items'] as List<dynamic>? ?? const <dynamic>[])) {
        if (rawItem is! Map) {
          shouldPrune = true;
          continue;
        }
        final item = SavedJobRecord(
          jobId: _asTrimmedString(rawItem['jobId']),
          timeStamp: _asInt(rawItem['timeStamp']),
        );
        if (item.jobId.isEmpty) {
          shouldPrune = true;
          continue;
        }
        items.add(item);
      }
      if (shouldPrune) {
        await _storeCache(uid, items);
      }
      return items;
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  static Future<void> _storeCache(
    String uid,
    List<SavedJobRecord> items,
  ) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix$uid',
      jsonEncode({
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'items': items
            .map((item) => {
                  'jobId': item.jobId,
                  'timeStamp': item.timeStamp,
                })
            .toList(growable: false),
      }),
    );
  }

  static Future<void> _invalidateCache(String uid) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove('$_prefsPrefix${uid.trim()}');
  }
}
