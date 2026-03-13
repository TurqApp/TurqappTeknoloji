import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';

class OpticalFormRepository extends GetxService {
  OpticalFormRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'optical_form_repository_v1';
  final Map<String, _TimedValue<dynamic>> _memory = <String, _TimedValue<dynamic>>{};
  SharedPreferences? _prefs;

  static OpticalFormRepository ensure() {
    if (Get.isRegistered<OpticalFormRepository>()) {
      return Get.find<OpticalFormRepository>();
    }
    return Get.put(OpticalFormRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Future<OpticalFormModel?> fetchById(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final key = 'doc:$docId';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedMap(key);
      if (cached != null) {
        return OpticalFormModel.fromMap(cached, docId);
      }
    }
    final doc = await _firestore.collection('optikForm').doc(docId).get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data() ?? const {});
    await _storeMap(key, data);
    return OpticalFormModel.fromMap(data, doc.id);
  }

  Future<List<OpticalFormModel>> fetchByOwner(
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final key = 'owner:$userId';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedList(key);
      if (cached != null) {
        return cached
            .map((e) => OpticalFormModel.fromMap(e, (e['docID'] ?? '').toString()))
            .toList(growable: false);
      }
    }

    final snap = await _firestore
        .collection('optikForm')
        .where('userID', isEqualTo: userId)
        .get(const GetOptions(source: Source.serverAndCache));
    final items = snap.docs
        .map((doc) => OpticalFormModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
    await _storePrimitive(
      key,
      items
          .map((e) => <String, dynamic>{
                'docID': e.docID,
                'name': e.name,
                'userID': e.userID,
                'cevaplar': e.cevaplar,
                'max': e.max,
                'baslangic': e.baslangic,
                'bitis': e.bitis,
                'kisitlama': e.kisitlama,
              })
          .toList(growable: false),
    );
    return items;
  }

  Future<List<OpticalFormModel>> fetchByIds(
    List<String> docIds, {
    bool preferCache = true,
  }) async {
    final ids = docIds.where((e) => e.trim().isNotEmpty).toList(growable: false);
    if (ids.isEmpty) return const <OpticalFormModel>[];
    final byId = <String, OpticalFormModel>{};
    const chunkSize = 10;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize > ids.length) ? ids.length : i + chunkSize;
      final chunk = ids.sublist(i, end);
      for (final id in chunk) {
        if (preferCache) {
          final cached = await fetchById(id, preferCache: true);
          if (cached != null) byId[id] = cached;
        }
      }
      final missing = chunk.where((id) => !byId.containsKey(id)).toList();
      if (missing.isEmpty) continue;
      final snap = await _firestore
          .collection('optikForm')
          .where(FieldPath.documentId, whereIn: missing)
          .get(const GetOptions(source: Source.serverAndCache));
      for (final doc in snap.docs) {
        final item = OpticalFormModel.fromMap(doc.data(), doc.id);
        byId[doc.id] = item;
        await _storeMap('doc:${doc.id}', doc.data());
      }
    }
    return ids.where(byId.containsKey).map((id) => byId[id]!).toList(growable: false);
  }

  Future<List<OpticalFormModel>> fetchAnsweredByUser(
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final key = 'answered:$userId';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedList(key);
      if (cached != null) {
        return cached
            .map((e) => OpticalFormModel.fromMap(e, (e['docID'] ?? '').toString()))
            .toList(growable: false);
      }
    }

    final answersSnap = await _firestore
        .collectionGroup('Yanitlar')
        .where(FieldPath.documentId, isEqualTo: userId)
        .get(const GetOptions(source: Source.serverAndCache));
    final formIds = <String>{
      for (final doc in answersSnap.docs)
        if (doc.reference.parent.parent != null &&
            doc.reference.parent.parent!.parent.id == 'optikForm')
          doc.reference.parent.parent!.id,
    }.toList(growable: false);
    final items = await fetchByIds(formIds, preferCache: true);
    await _storePrimitive(
      key,
      items
          .map((e) => <String, dynamic>{
                'docID': e.docID,
                'name': e.name,
                'userID': e.userID,
                'cevaplar': e.cevaplar,
                'max': e.max,
                'baslangic': e.baslangic,
                'bitis': e.bitis,
                'kisitlama': e.kisitlama,
              })
          .toList(growable: false),
    );
    return items;
  }

  Future<int> fetchAnswerCount(
    String formId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final key = 'count:$formId';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedInt(key);
      if (cached != null) return cached;
    }
    final snapshot = await _firestore
        .collection('optikForm')
        .doc(formId)
        .collection('Yanitlar')
        .get();
    final total = snapshot.docs.length;
    await _storePrimitive(key, total);
    return total;
  }

  Future<List<String>> fetchUserAnswers(
    String formId,
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final key = 'answers:$formId:$userId';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedStringList(key);
      if (cached != null) return cached;
    }
    final doc = await _firestore
        .collection('optikForm')
        .doc(formId)
        .collection('Yanitlar')
        .doc(userId)
        .get();
    final answers = List<String>.from((doc.data()?['cevaplar'] as List?) ?? const []);
    await _storePrimitive(key, answers);
    return answers;
  }

  Future<void> initializeUserAnswers(
    String formId,
    String userId,
    int questionCount,
  ) async {
    final answers = List<String>.filled(questionCount, '');
    await _firestore
        .collection('optikForm')
        .doc(formId)
        .collection('Yanitlar')
        .doc(userId)
        .set({
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
      'cevaplar': answers,
    }, SetOptions(merge: true));
    await _storePrimitive('answers:$formId:$userId', answers);
  }

  Future<void> saveUserAnswers(
    String formId,
    String userId, {
    required List<String> answers,
    required String ogrenciNo,
    required String fullName,
  }) async {
    await _firestore
        .collection('optikForm')
        .doc(formId)
        .collection('Yanitlar')
        .doc(userId)
        .update({
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
      'cevaplar': answers,
      'ogrenciNo': ogrenciNo,
      'fullName': fullName,
    });
    await _storePrimitive('answers:$formId:$userId', answers);
  }

  Future<void> deleteForm(String formId) async {
    await _firestore.collection('optikForm').doc(formId).delete();
    _memory.remove('doc:$formId');
    _memory.remove('count:$formId');
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove('$_prefsPrefix:doc:$formId');
    await _prefs?.remove('$_prefsPrefix:count:$formId');
  }

  Future<Map<String, dynamic>?> _getCachedMap(String key) async {
    final cached = await _getCachedValue(key);
    if (cached is Map<String, dynamic>) return cached;
    return null;
  }

  Future<int?> _getCachedInt(String key) async {
    final cached = await _getCachedValue(key);
    if (cached is int) return cached;
    return null;
  }

  Future<List<String>?> _getCachedStringList(String key) async {
    final cached = await _getCachedValue(key);
    if (cached is List) {
      return cached.map((e) => e.toString()).toList(growable: false);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> _getCachedList(String key) async {
    final cached = await _getCachedValue(key);
    if (cached is List) {
      return cached
          .map((e) => Map<String, dynamic>.from((e as Map)))
          .toList(growable: false);
    }
    return null;
  }

  Future<dynamic> _getCachedValue(String key) async {
    final memory = _memory[key];
    if (memory != null && DateTime.now().difference(memory.cachedAt) <= _ttl) {
      return memory.value;
    }
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_prefsPrefix:$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      if (DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) > _ttl) {
        return null;
      }
      final value = decoded['v'];
      _memory[key] = _TimedValue<dynamic>(
        value: value,
        cachedAt: DateTime.now(),
      );
      return value;
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeMap(String key, Map<String, dynamic> value) =>
      _storePrimitive(key, value);

  Future<void> _storePrimitive(String key, dynamic value) async {
    final now = DateTime.now();
    _memory[key] = _TimedValue<dynamic>(value: value, cachedAt: now);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix:$key',
      jsonEncode({
        't': now.millisecondsSinceEpoch,
        'v': value,
      }),
    );
  }
}

class _TimedValue<T> {
  const _TimedValue({
    required this.value,
    required this.cachedAt,
  });

  final T value;
  final DateTime cachedAt;
}
