import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';

class OpticalFormOwnerQuery {
  const OpticalFormOwnerQuery({
    required this.userId,
  });

  final String userId;

  String buildScopeId() => CacheScopeNamespace.buildQueryScope(
        userId: userId,
        limit: 0,
        scopeTag: 'owner',
        schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
          OpticalFormSnapshotRepository.ownerSurfaceKey,
        ),
        qualifiers: <String, Object?>{
          'owner': userId.trim(),
        },
      );
}

class OpticalFormAnsweredQuery {
  const OpticalFormAnsweredQuery({
    required this.userId,
    required this.limit,
  });

  final String userId;
  final int limit;

  int get effectiveLimit =>
      ReadBudgetRegistry.resolveOpticalFormAnsweredInitialLimit(limit);

  String buildScopeId() => CacheScopeNamespace.buildQueryScope(
        userId: userId,
        limit: effectiveLimit,
        scopeTag: 'answered',
        schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
          OpticalFormSnapshotRepository.answeredSurfaceKey,
        ),
        qualifiers: <String, Object?>{
          'answered': userId.trim(),
          'limit': effectiveLimit,
        },
      );
}

OpticalFormSnapshotRepository? maybeFindOpticalFormSnapshotRepository() {
  final isRegistered = Get.isRegistered<OpticalFormSnapshotRepository>();
  if (!isRegistered) return null;
  return Get.find<OpticalFormSnapshotRepository>();
}

OpticalFormSnapshotRepository ensureOpticalFormSnapshotRepository() {
  final existing = maybeFindOpticalFormSnapshotRepository();
  if (existing != null) return existing;
  return Get.put(OpticalFormSnapshotRepository(), permanent: true);
}

class OpticalFormSnapshotRepository extends GetxService {
  OpticalFormSnapshotRepository();

  static const String ownerSurfaceKey = 'optical_form_owner_snapshot';
  static const String answeredSurfaceKey = 'optical_form_answered_snapshot';

  late final CacheFirstCoordinator<List<OpticalFormModel>> _coordinator =
      CacheFirstCoordinator<List<OpticalFormModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<OpticalFormModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<OpticalFormModel>>(
      prefsPrefix: 'optical_form_snapshot_v1',
      encode: _encodeItems,
      decode: _decodeItems,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<OpticalFormModel>>(),
    policy: CacheFirstPolicyRegistry.policyForSurface(ownerSurfaceKey),
  );

  late final CacheFirstQueryPipeline<OpticalFormOwnerQuery,
          List<OpticalFormModel>, List<OpticalFormModel>> _ownerPipeline =
      CacheFirstQueryPipeline<OpticalFormOwnerQuery, List<OpticalFormModel>,
          List<OpticalFormModel>>(
    surfaceKey: ownerSurfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.buildScopeId(),
    fetchRaw: _fetchOwnerItems,
    resolve: (items) => items,
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      ownerSurfaceKey,
    ),
  );

  late final CacheFirstQueryPipeline<OpticalFormAnsweredQuery,
          List<OpticalFormModel>, List<OpticalFormModel>> _answeredPipeline =
      CacheFirstQueryPipeline<OpticalFormAnsweredQuery, List<OpticalFormModel>,
          List<OpticalFormModel>>(
    surfaceKey: answeredSurfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.buildScopeId(),
    fetchRaw: _fetchAnsweredItems,
    resolve: (items) => items,
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      answeredSurfaceKey,
    ),
  );

  Future<CachedResource<List<OpticalFormModel>>> loadCachedOwner({
    required String userId,
  }) {
    final query = OpticalFormOwnerQuery(userId: userId);
    return _bootstrap(
      surfaceKey: ownerSurfaceKey,
      userId: userId,
      scopeId: query.buildScopeId(),
    );
  }

  Future<CachedResource<List<OpticalFormModel>>> loadCachedAnswered({
    required String userId,
    int limit = ReadBudgetRegistry.opticalFormAnsweredInitialLimit,
  }) {
    final effectiveLimit =
        ReadBudgetRegistry.resolveOpticalFormAnsweredInitialLimit(limit);
    final query = OpticalFormAnsweredQuery(
      userId: userId,
      limit: effectiveLimit,
    );
    return _bootstrap(
      surfaceKey: answeredSurfaceKey,
      userId: userId,
      scopeId: query.buildScopeId(),
    );
  }

  Future<CachedResource<List<OpticalFormModel>>> _bootstrap({
    required String surfaceKey,
    required String userId,
    required String scopeId,
  }) {
    final key = ScopedSnapshotKey(
      surfaceKey: surfaceKey,
      userId: userId.trim(),
      scopeId: scopeId,
    );
    return _coordinator.bootstrap(
      key,
      schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
        surfaceKey,
      ),
    );
  }

  Stream<CachedResource<List<OpticalFormModel>>> openOwner({
    required String userId,
    bool forceSync = false,
  }) {
    return _ownerPipeline.open(
      OpticalFormOwnerQuery(userId: userId),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<OpticalFormModel>>> loadOwner({
    required String userId,
    bool forceSync = false,
  }) {
    return openOwner(
      userId: userId,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<OpticalFormModel>>> openAnswered({
    required String userId,
    int limit = ReadBudgetRegistry.opticalFormAnsweredInitialLimit,
    bool forceSync = false,
  }) {
    final effectiveLimit =
        ReadBudgetRegistry.resolveOpticalFormAnsweredInitialLimit(limit);
    return _answeredPipeline.open(
      OpticalFormAnsweredQuery(
        userId: userId,
        limit: effectiveLimit,
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<OpticalFormModel>>> loadAnswered({
    required String userId,
    int limit = ReadBudgetRegistry.opticalFormAnsweredInitialLimit,
    bool forceSync = false,
  }) {
    return openAnswered(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Map<String, dynamic> _encodeItems(List<OpticalFormModel> items) {
    return <String, dynamic>{
      'items': items
          .map(
            (item) => <String, dynamic>{
              'docID': item.docID,
              'name': item.name,
              'userID': item.userID,
              'cevaplar': List<String>.from(item.cevaplar, growable: false),
              'max': item.max,
              'baslangic': item.baslangic,
              'bitis': item.bitis,
              'kisitlama': item.kisitlama,
            },
          )
          .toList(growable: false),
    };
  }

  List<OpticalFormModel> _decodeItems(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
    return rawItems
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
          return OpticalFormModel(
            docID: (item['docID'] ?? '').toString(),
            name: (item['name'] ?? '').toString(),
            userID: (item['userID'] ?? '').toString(),
            cevaplar: ((item['cevaplar'] as List<dynamic>?) ?? const [])
                .map((answer) => answer.toString())
                .where((answer) => answer.trim().isNotEmpty)
                .toList(growable: false),
            max: item['max'] is num
                ? item['max'] as num
                : num.tryParse((item['max'] ?? '0').toString()) ?? 0,
            baslangic: item['baslangic'] is num
                ? item['baslangic'] as num
                : num.tryParse((item['baslangic'] ?? '0').toString()) ?? 0,
            bitis: item['bitis'] is num
                ? item['bitis'] as num
                : num.tryParse((item['bitis'] ?? '0').toString()) ?? 0,
            kisitlama: item['kisitlama'] == true,
          );
        })
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<OpticalFormModel>> _fetchOwnerItems(
    OpticalFormOwnerQuery query,
  ) async {
    final normalizedUserId = query.userId.trim();
    if (normalizedUserId.isEmpty) return const <OpticalFormModel>[];
    final snapshot = await AppFirestore.instance
        .collection('optikForm')
        .where('userID', isEqualTo: normalizedUserId)
        .get(const GetOptions(source: Source.serverAndCache));
    final items = snapshot.docs
        .map((doc) => OpticalFormModel.fromMap(doc.data(), doc.id))
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => b.docID.compareTo(a.docID));
    return items;
  }

  Future<List<OpticalFormModel>> _fetchAnsweredItems(
    OpticalFormAnsweredQuery query,
  ) async {
    final normalizedUserId = query.userId.trim();
    if (normalizedUserId.isEmpty) return const <OpticalFormModel>[];
    final normalizedLimit = query.effectiveLimit;
    final answeredRefsSnap = await AppFirestore.instance
        .collection('users')
        .doc(normalizedUserId)
        .collection('answered_optical_forms')
        .get(const GetOptions(source: Source.serverAndCache));
    final formIds = <String>{
      for (final refDoc in answeredRefsSnap.docs)
        if (refDoc.id.trim().isNotEmpty) refDoc.id.trim(),
    };
    if (formIds.isEmpty) {
      final answersSnap = await AppFirestore.instance
          .collectionGroup('Yanitlar')
          .where(FieldPath.documentId, isEqualTo: normalizedUserId)
          .get(const GetOptions(source: Source.serverAndCache));
      final backfillEntries = <String, int>{};
      for (final doc in answersSnap.docs) {
        final parentRef = doc.reference.parent.parent;
        if (parentRef == null || parentRef.parent.id != 'optikForm') {
          continue;
        }
        final formId = parentRef.id.trim();
        if (formId.isEmpty) continue;
        formIds.add(formId);
        final rawTimestamp = doc.data()['timeStamp'];
        final timestamp = rawTimestamp is num ? rawTimestamp.toInt() : 0;
        final previous = backfillEntries[formId] ?? 0;
        if (timestamp > previous) {
          backfillEntries[formId] = timestamp;
        }
      }
      if (backfillEntries.isNotEmpty) {
        await _backfillAnsweredOpticalFormRefs(
          normalizedUserId,
          backfillEntries,
        );
      }
    }
    if (formIds.isEmpty) return const <OpticalFormModel>[];
    final items = await _fetchByIds(formIds.toList(growable: false));
    items.sort((a, b) => b.baslangic.compareTo(a.baslangic));
    return items.take(normalizedLimit).toList(growable: false);
  }

  Future<void> _backfillAnsweredOpticalFormRefs(
    String userId,
    Map<String, int> formTimestamps,
  ) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty || formTimestamps.isEmpty) return;

    final firestore = AppFirestore.instance;
    final entries = formTimestamps.entries.toList(growable: false);
    for (var index = 0; index < entries.length; index += 200) {
      final batch = firestore.batch();
      final chunk = entries.skip(index).take(200);
      for (final entry in chunk) {
        final timestamp = entry.value > 0
            ? entry.value
            : DateTime.now().millisecondsSinceEpoch;
        final ref = firestore
            .collection('users')
            .doc(normalizedUserId)
            .collection('answered_optical_forms')
            .doc(entry.key);
        batch.set(
          ref,
          <String, dynamic>{
            'opticalFormId': entry.key,
            'updatedDate': timestamp,
            'timeStamp': timestamp,
          },
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
  }

  Future<List<OpticalFormModel>> _fetchByIds(List<String> docIds) async {
    final ids = docIds
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (ids.isEmpty) return const <OpticalFormModel>[];
    final byId = <String, OpticalFormModel>{};
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.skip(i).take(10).toList(growable: false);
      final snap = await AppFirestore.instance
          .collection('optikForm')
          .where(FieldPath.documentId, whereIn: chunk)
          .get(const GetOptions(source: Source.serverAndCache));
      for (final doc in snap.docs) {
        byId[doc.id] = OpticalFormModel.fromMap(doc.data(), doc.id);
      }
    }
    return ids
        .map((id) => byId[id])
        .whereType<OpticalFormModel>()
        .toList(growable: false);
  }
}

extension OpticalFormSnapshotRepositoryInvalidationPart
    on OpticalFormSnapshotRepository {
  Future<void> invalidateUserScopedSurfaces(String userId) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return;
    await Future.wait(<Future<void>>[
      _coordinator.clearSurface(
        OpticalFormSnapshotRepository.ownerSurfaceKey,
        userId: normalized,
      ),
      _coordinator.clearSurface(
        OpticalFormSnapshotRepository.answeredSurfaceKey,
        userId: normalized,
      ),
    ]);
  }

  Future<void> invalidateAnsweredSurface(String userId) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return;
    await _coordinator.clearSurface(
      OpticalFormSnapshotRepository.answeredSurfaceKey,
      userId: normalized,
    );
  }

  Future<void> invalidateAllSurfaces() async {
    await Future.wait(<Future<void>>[
      _coordinator.clearSurface(OpticalFormSnapshotRepository.ownerSurfaceKey),
      _coordinator.clearSurface(
        OpticalFormSnapshotRepository.answeredSurfaceKey,
      ),
    ]);
  }
}
