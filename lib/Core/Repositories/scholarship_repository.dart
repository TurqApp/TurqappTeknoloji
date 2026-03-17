import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/scholarship_firestore_path.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';

class ScholarshipRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'scholarship_repository_v1:';
  static const String _applyPrefix = 'scholarship_apply_repository_v1:';
  static const String _countKey = 'scholarship_total_count_v1';

  final Map<String, _TimedScholarship> _memory = <String, _TimedScholarship>{};
  final Map<String, _TimedScholarshipList> _queryMemory =
      <String, _TimedScholarshipList>{};
  final Map<String, _TimedScholarshipApply> _applyMemory =
      <String, _TimedScholarshipApply>{};
  SharedPreferences? _prefs;

  static ScholarshipRepository ensure() {
    if (Get.isRegistered<ScholarshipRepository>()) {
      return Get.find<ScholarshipRepository>();
    }
    return Get.put(ScholarshipRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Future<IndividualScholarshipsModel?> fetchById(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final raw = await fetchRawById(
      docId,
      preferCache: preferCache,
      forceRefresh: forceRefresh,
    );
    if (raw == null) return null;
    return IndividualScholarshipsModel.fromJson(raw);
  }

  Future<Map<String, dynamic>?> fetchRawById(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cleanId = docId.trim();
    if (cleanId.isEmpty) return null;
    if (!forceRefresh && preferCache) {
      final memory = _readMemory(cleanId);
      if (memory != null) return memory;
      final disk = await _readPrefs(cleanId);
      if (disk != null) {
        _memory[cleanId] = _TimedScholarship(
          data: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final doc = await ScholarshipFirestorePath.doc(cleanId).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    await _store(cleanId, data);
    return data;
  }

  Map<String, dynamic>? _readMemory(String docId) {
    final cached = _memory[docId];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.cachedAt) > _ttl) {
      _memory.remove(docId);
      return null;
    }
    return cached.data;
  }

  Future<Map<String, dynamic>?> _readPrefs(String docId) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_prefsPrefix$docId');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = (decoded['savedAt'] as num?)?.toInt() ?? 0;
      if (savedAt <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(savedAt);
      if (DateTime.now().difference(cachedAt) > _ttl) return null;
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  Future<void> _store(String docId, Map<String, dynamic> data) async {
    _memory[docId] = _TimedScholarship(
      data: data,
      cachedAt: DateTime.now(),
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix$docId',
      jsonEncode({
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }),
    );
  }

  Future<List<Map<String, dynamic>>> fetchMyScholarshipsRaw(
    String uid, {
    int limit = 50,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return const <Map<String, dynamic>>[];
    final cacheKey = 'query:owner:$cleanUid:$limit';

    if (!forceRefresh && preferCache) {
      final memory = _readQueryMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _readQueryPrefs(cacheKey);
      if (disk != null) {
        _queryMemory[cacheKey] = _TimedScholarshipList(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    if (cacheOnly) return const <Map<String, dynamic>>[];

    final snapshot = await ScholarshipFirestorePath.collection()
        .where('userID', isEqualTo: cleanUid)
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get();

    final items = snapshot.docs
        .map((doc) => <String, dynamic>{
              ...Map<String, dynamic>.from(doc.data()),
              'docId': doc.id,
            })
        .toList(growable: false);
    await _storeQueryDocs(cacheKey, items);
    return items;
  }

  Future<List<Map<String, dynamic>>> fetchLatestRaw({
    int limit = 200,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'query:latest:$limit';
    if (!forceRefresh && preferCache) {
      final memory = _readQueryMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _readQueryPrefs(cacheKey);
      if (disk != null) {
        _queryMemory[cacheKey] = _TimedScholarshipList(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    if (cacheOnly) return const <Map<String, dynamic>>[];

    final snapshot = await ScholarshipFirestorePath.collection()
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get();

    final items = snapshot.docs
        .map((doc) => <String, dynamic>{
              ...Map<String, dynamic>.from(doc.data()),
              'docId': doc.id,
            })
        .toList(growable: false);
    await _storeQueryDocs(cacheKey, items);
    return items;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchLatestPage({
    int limit = 30,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> query = ScholarshipFirestorePath.collection()
        .orderBy('timeStamp', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.get();
  }

  Future<List<Map<String, dynamic>>> fetchByIdsRaw(
    List<String> docIds,
  ) async {
    final orderedIds =
        docIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toList();
    if (orderedIds.isEmpty) return const <Map<String, dynamic>>[];

    const chunkSize = 10;
    final byId = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (var i = 0; i < orderedIds.length; i += chunkSize) {
      final end =
          (i + chunkSize > orderedIds.length) ? orderedIds.length : i + chunkSize;
      final chunk = orderedIds.sublist(i, end);
      final snap = await ScholarshipFirestorePath.collection()
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        byId[doc.id] = doc;
      }
    }

    return orderedIds
        .where(byId.containsKey)
        .map((id) => <String, dynamic>{
              ...Map<String, dynamic>.from(byId[id]!.data()),
              'docId': id,
            })
        .toList(growable: false);
  }

  Future<int> fetchTotalCount({
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && preferCache) {
      final cached = await _getRawDoc(_countKey);
      final count = (cached?['count'] as num?)?.toInt();
      if (count != null) return count;
    }
    final agg = await ScholarshipFirestorePath.collection().count().get();
    final count = agg.count ?? 0;
    await _storeRawDoc(_countKey, <String, dynamic>{'count': count});
    return count;
  }

  Future<List<Map<String, dynamic>>> fetchAppliedByUserRaw(
    String uid, {
    int limit = 50,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return const <Map<String, dynamic>>[];
    final cacheKey = 'query:applied:$cleanUid:$limit';

    if (!forceRefresh && preferCache) {
      final memory = _readQueryMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _readQueryPrefs(cacheKey);
      if (disk != null) {
        _queryMemory[cacheKey] = _TimedScholarshipList(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    if (cacheOnly) return const <Map<String, dynamic>>[];

    final snapshot = await ScholarshipFirestorePath.collection()
        .where('basvurular', arrayContains: cleanUid)
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get();

    final items = snapshot.docs
        .map((doc) => <String, dynamic>{
              ...Map<String, dynamic>.from(doc.data()),
              'docId': doc.id,
            })
        .toList(growable: false);
    await _storeQueryDocs(cacheKey, items);
    return items;
  }

  Future<List<Map<String, dynamic>>> fetchByArrayMembershipRaw(
    String field,
    String uid, {
    int limit = 50,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cleanUid = uid.trim();
    final cleanField = field.trim();
    if (cleanUid.isEmpty || cleanField.isEmpty) {
      return const <Map<String, dynamic>>[];
    }
    final cacheKey = 'query:membership:$cleanField:$cleanUid:$limit';

    if (!forceRefresh && preferCache) {
      final memory = _readQueryMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _readQueryPrefs(cacheKey);
      if (disk != null) {
        _queryMemory[cacheKey] = _TimedScholarshipList(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    if (cacheOnly) return const <Map<String, dynamic>>[];

    final snapshot = await ScholarshipFirestorePath.collection()
        .where(cleanField, arrayContains: cleanUid)
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get();

    final items = snapshot.docs
        .map((doc) => <String, dynamic>{
              ...Map<String, dynamic>.from(doc.data()),
              'docId': doc.id,
            })
        .toList(growable: false);
    await _storeQueryDocs(cacheKey, items);
    return items;
  }

  Future<bool> hasUserApplied(
    String scholarshipId,
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cleanScholarshipId = scholarshipId.trim();
    final cleanUserId = userId.trim();
    if (cleanScholarshipId.isEmpty || cleanUserId.isEmpty) return false;
    final key = '$cleanScholarshipId::$cleanUserId';

    if (!forceRefresh && preferCache) {
      final memory = _readApplyMemory(key);
      if (memory != null) return memory;
      final disk = await _readApplyPrefs(key);
      if (disk != null) {
        _applyMemory[key] = _TimedScholarshipApply(
          value: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final docRef = ScholarshipFirestorePath.doc(cleanScholarshipId);
    final doc = await docRef.collection('Basvurular').doc(cleanUserId).get();
    var applied = doc.exists;
    if (!applied) {
      final parentDoc = await docRef.get();
      final applicants =
          List<String>.from(parentDoc.data()?['basvurular'] ?? const []);
      applied = applicants.contains(cleanUserId);
    }

    await _storeApply(key, applied);
    return applied;
  }

  Future<void> setUserAppliedCache(
    String scholarshipId,
    String userId,
    bool value,
  ) async {
    final cleanScholarshipId = scholarshipId.trim();
    final cleanUserId = userId.trim();
    if (cleanScholarshipId.isEmpty || cleanUserId.isEmpty) return;
    await _storeApply('$cleanScholarshipId::$cleanUserId', value);
  }

  Future<List<String>> fetchApplicantIds(
    String scholarshipId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cleanId = scholarshipId.trim();
    if (cleanId.isEmpty) return const <String>[];
    final cacheKey = 'applicants:$cleanId';
    if (!forceRefresh && preferCache) {
      final cached = await _getRawDoc(cacheKey);
      if (cached != null) {
        return List<String>.from(cached['ids'] ?? const <String>[]);
      }
    }

    final doc = await ScholarshipFirestorePath.doc(cleanId).get();
    final ids = List<String>.from(doc.data()?['basvurular'] ?? const <String>[]);
    await _storeRawDoc(cacheKey, <String, dynamic>{'ids': ids});
    return ids;
  }

  Future<int> fetchApplicantCount(
    String scholarshipId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final ids = await fetchApplicantIds(
      scholarshipId,
      preferCache: preferCache,
      forceRefresh: forceRefresh,
    );
    return ids.length;
  }

  Future<bool> toggleLike(
    String scholarshipId, {
    required String userId,
  }) async {
    return _toggleArrayMembership(
      scholarshipId,
      userId: userId,
      field: 'begeniler',
    );
  }

  Future<bool> toggleBookmark(
    String scholarshipId, {
    required String userId,
  }) async {
    return _toggleArrayMembership(
      scholarshipId,
      userId: userId,
      field: 'kaydedenler',
    );
  }

  Future<bool> _toggleArrayMembership(
    String scholarshipId, {
    required String userId,
    required String field,
  }) async {
    final cleanId = scholarshipId.trim();
    final cleanUserId = userId.trim();
    if (cleanId.isEmpty || cleanUserId.isEmpty) return false;
    final docRef = ScholarshipFirestorePath.doc(cleanId);
    final doc = await docRef.get();
    if (!doc.exists) return false;
    final current =
        List<String>.from(doc.data()?[field] ?? const <String>[]);
    final contains = current.contains(cleanUserId);
    final next = contains
        ? current.where((e) => e != cleanUserId).toList(growable: false)
        : <String>[...current, cleanUserId];
    await docRef.update({field: next});

    final existingRaw = await fetchRawById(
      cleanId,
      preferCache: true,
      forceRefresh: false,
    );
    if (existingRaw != null) {
      final updated = Map<String, dynamic>.from(existingRaw)..[field] = next;
      await _store(cleanId, updated);
    }
    await _invalidateQueryPrefix('query:membership:$field:$cleanUserId:');
    return !contains;
  }

  List<Map<String, dynamic>>? _readQueryMemory(String key) {
    final cached = _queryMemory[key];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.cachedAt) > _ttl) {
      _queryMemory.remove(key);
      return null;
    }
    return cached.items;
  }

  Future<List<Map<String, dynamic>>?> _readQueryPrefs(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_prefsPrefix:$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = (decoded['savedAt'] as num?)?.toInt() ?? 0;
      if (savedAt <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(savedAt);
      if (DateTime.now().difference(cachedAt) > _ttl) return null;
      final items = (decoded['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
      return items;
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeQueryDocs(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    _queryMemory[key] = _TimedScholarshipList(
      items: items,
      cachedAt: DateTime.now(),
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix:$key',
      jsonEncode({
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'items': items,
      }),
    );
  }

  Future<void> _invalidateQueryPrefix(String prefix) async {
    _queryMemory.removeWhere((key, _) => key.startsWith(prefix));
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    if (prefs == null) return;
    final keys = prefs.getKeys().where((key) {
      if (!key.startsWith('$_prefsPrefix:')) return false;
      final scoped = key.substring('$_prefsPrefix:'.length);
      return scoped.startsWith(prefix);
    }).toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  bool? _readApplyMemory(String key) {
    final cached = _applyMemory[key];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.cachedAt) > _ttl) {
      _applyMemory.remove(key);
      return null;
    }
    return cached.value;
  }

  Future<bool?> _readApplyPrefs(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_applyPrefix$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedAt = (decoded['savedAt'] as num?)?.toInt() ?? 0;
      if (savedAt <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(savedAt);
      if (DateTime.now().difference(cachedAt) > _ttl) return null;
      final value = decoded['value'];
      if (value is bool) return value;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeApply(String key, bool value) async {
    _applyMemory[key] = _TimedScholarshipApply(
      value: value,
      cachedAt: DateTime.now(),
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_applyPrefix$key',
      jsonEncode({
        'savedAt': DateTime.now().millisecondsSinceEpoch,
        'value': value,
      }),
    );
  }

  Future<void> _storeRawDoc(String cacheKey, Map<String, dynamic> data) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix:$cacheKey',
      jsonEncode({
        't': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }),
    );
  }

  Future<Map<String, dynamic>?> _getRawDoc(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_prefsPrefix:$cacheKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      final fresh =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <=
              _ttl;
      if (!fresh) return null;
      return Map<String, dynamic>.from(
        (decoded['data'] as Map?) ?? const <String, dynamic>{},
      );
    } catch (_) {
      return null;
    }
  }
}

class _TimedScholarship {
  const _TimedScholarship({
    required this.data,
    required this.cachedAt,
  });

  final Map<String, dynamic> data;
  final DateTime cachedAt;
}

class _TimedScholarshipList {
  const _TimedScholarshipList({
    required this.items,
    required this.cachedAt,
  });

  final List<Map<String, dynamic>> items;
  final DateTime cachedAt;
}

class _TimedScholarshipApply {
  const _TimedScholarshipApply({
    required this.value,
    required this.cachedAt,
  });

  final bool value;
  final DateTime cachedAt;
}
