part of 'practice_exam_snapshot_repository.dart';

const String _practiceExamHomeSurfaceKey = 'practice_exam_home_snapshot';
const String _practiceExamSearchSurfaceKey = 'practice_exam_search_snapshot';
const String _practiceExamOwnerSurfaceKey = 'practice_exam_owner_snapshot';
const String _practiceExamTypeSurfaceKey = 'practice_exam_type_snapshot';
const String _practiceExamAnsweredSurfaceKey =
    'practice_exam_answered_snapshot';

class PracticeExamOwnerQuery {
  const PracticeExamOwnerQuery({
    required this.userId,
  });

  final String userId;

  String buildScopeId({
    required int schemaVersion,
  }) {
    return CacheScopeNamespace.buildQueryScope(
      userId: userId,
      limit: 0,
      scopeTag: 'owner',
      schemaVersion: schemaVersion,
      qualifiers: <String, Object?>{
        'owner': userId.trim(),
      },
    );
  }
}

class PracticeExamTypeQuery {
  const PracticeExamTypeQuery({
    required this.userId,
    required this.examType,
  });

  final String userId;
  final String examType;

  String buildScopeId({
    required int schemaVersion,
  }) {
    return CacheScopeNamespace.buildQueryScope(
      userId: userId,
      limit: 0,
      scopeTag: 'type',
      schemaVersion: schemaVersion,
      qualifiers: <String, Object?>{
        'examType': examType.trim(),
      },
    );
  }
}

class PracticeExamAnsweredQuery {
  const PracticeExamAnsweredQuery({
    required this.userId,
    required this.limit,
  });

  final String userId;
  final int limit;

  int get effectiveLimit =>
      ReadBudgetRegistry.resolvePracticeExamAnsweredInitialLimit(limit);

  String buildScopeId({
    required int schemaVersion,
  }) {
    return CacheScopeNamespace.buildQueryScope(
      userId: userId,
      limit: effectiveLimit,
      scopeTag: 'answered',
      schemaVersion: schemaVersion,
      qualifiers: <String, Object?>{
        'answered': userId.trim(),
        'limit': effectiveLimit,
      },
    );
  }
}

class PracticeExamSnapshotRepository extends GetxService {
  PracticeExamSnapshotRepository();

  final PracticeExamRepository _practiceExamRepository =
      ensurePracticeExamRepository();

  late final CacheFirstCoordinator<List<SinavModel>> _coordinator =
      _buildPracticeExamSnapshotCoordinator();

  late final EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>
      _homeAdapter = _buildPracticeExamSnapshotAdapter(
    surfaceKey: _practiceExamHomeSurfaceKey,
    coordinator: _coordinator,
    repository: _practiceExamRepository,
  );

  late final EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>
      _searchAdapter = _buildPracticeExamSnapshotAdapter(
    surfaceKey: _practiceExamSearchSurfaceKey,
    coordinator: _coordinator,
    repository: _practiceExamRepository,
  );

  late final CacheFirstQueryPipeline<PracticeExamOwnerQuery, List<SinavModel>,
          List<SinavModel>> _ownerPipeline =
      CacheFirstQueryPipeline<PracticeExamOwnerQuery, List<SinavModel>,
          List<SinavModel>>(
    surfaceKey: _practiceExamOwnerSurfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.buildScopeId(
      schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
        _practiceExamOwnerSurfaceKey,
      ),
    ),
    fetchRaw: _fetchPracticeExamOwnerItems,
    resolve: (items) => items,
    isEmpty: (items) => items.isEmpty,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      _practiceExamOwnerSurfaceKey,
    ),
  );

  late final CacheFirstQueryPipeline<PracticeExamTypeQuery, List<SinavModel>,
          List<SinavModel>> _typePipeline =
      CacheFirstQueryPipeline<PracticeExamTypeQuery, List<SinavModel>,
          List<SinavModel>>(
    surfaceKey: _practiceExamTypeSurfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.buildScopeId(
      schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
        _practiceExamTypeSurfaceKey,
      ),
    ),
    fetchRaw: _fetchPracticeExamTypeItems,
    resolve: (items) => items,
    isEmpty: (items) => items.isEmpty,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      _practiceExamTypeSurfaceKey,
    ),
  );

  late final CacheFirstQueryPipeline<PracticeExamAnsweredQuery,
          List<SinavModel>, List<SinavModel>> _answeredPipeline =
      CacheFirstQueryPipeline<PracticeExamAnsweredQuery, List<SinavModel>,
          List<SinavModel>>(
    surfaceKey: _practiceExamAnsweredSurfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.buildScopeId(
      schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
        _practiceExamAnsweredSurfaceKey,
      ),
    ),
    fetchRaw: _fetchPracticeExamAnsweredItems,
    resolve: (items) => items,
    isEmpty: (items) => items.isEmpty,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      _practiceExamAnsweredSurfaceKey,
    ),
  );
}

CacheFirstCoordinator<List<SinavModel>>
    _buildPracticeExamSnapshotCoordinator() {
  return CacheFirstCoordinator<List<SinavModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<SinavModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<SinavModel>>(
      prefsPrefix: 'practice_exam_snapshot_v1',
      encode: _encodePracticeExamSnapshotItems,
      decode: _decodePracticeExamSnapshotItems,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<SinavModel>>(),
    policy: CacheFirstPolicyRegistry.policyForSurface(
      _practiceExamHomeSurfaceKey,
    ),
  );
}

EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>
    _buildPracticeExamSnapshotAdapter({
  required String surfaceKey,
  required CacheFirstCoordinator<List<SinavModel>> coordinator,
  required PracticeExamRepository repository,
}) {
  return EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>(
    surfaceKey: surfaceKey,
    coordinator: coordinator,
    fetchDocIds: EducationTypesenseDocIdHydrationAdapter.defaultFetchDocIds,
    hydrate: (docIds) => repository.fetchByIds(docIds),
    loadWarmSnapshot: (query) => _loadPracticeExamWarmSnapshot(
      repository,
      query,
    ),
    isEmpty: (items) => items.isEmpty,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(surfaceKey),
  );
}

Future<List<SinavModel>?> _loadPracticeExamWarmSnapshot(
  PracticeExamRepository repository,
  EducationTypesenseDocIdQuery query,
) async {
  final raw = await TypesenseEducationSearchService.instance.searchHits(
    entity: query.entity,
    query: query.query,
    limit: query.limit,
    page: query.page,
    filterBy: query.filterBy,
    sortBy: query.sortBy,
    cacheOnly: true,
  );
  final docIds = raw.hits
      .map((hit) => (hit['docId'] ?? hit['id'] ?? '').toString().trim())
      .where((id) => id.isNotEmpty)
      .toList(growable: false);
  if (docIds.isEmpty) return null;
  final items = await repository.fetchByIds(
    docIds,
    cacheOnly: true,
  );
  return items.isEmpty ? null : items;
}

num _practiceExamSnapshotAsNum(Object? value, {num fallback = 0}) {
  if (value is num) return value;
  final normalized = value?.toString().trim() ?? '';
  if (normalized.isEmpty) return fallback;
  return num.tryParse(normalized) ?? fallback;
}

bool _practiceExamSnapshotAsBool(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase() ?? '';
  if (normalized.isEmpty) return fallback;
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return fallback;
}

SinavModel _practiceExamSnapshotFromDoc(
  String docId,
  Map<String, dynamic> data,
) {
  return SinavModel(
    docID: docId,
    cover: (data['cover'] ?? '').toString(),
    sinavTuru: (data['sinavTuru'] ?? '').toString(),
    timeStamp: _practiceExamSnapshotAsNum(data['timeStamp']),
    sinavAciklama: (data['sinavAciklama'] ?? '').toString(),
    sinavAdi: (data['sinavAdi'] ?? '').toString(),
    kpssSecilenLisans: (data['kpssSecilenLisans'] ?? '').toString(),
    dersler: (data['dersler'] is List)
        ? (data['dersler'] as List).map((e) => e.toString()).toList()
        : <String>[],
    taslak: _practiceExamSnapshotAsBool(data['taslak'], fallback: false),
    public: _practiceExamSnapshotAsBool(data['public'], fallback: true),
    userID: (data['userID'] ?? '').toString(),
    soruSayilari: (data['soruSayilari'] is List)
        ? (data['soruSayilari'] as List).map((e) => e.toString()).toList()
        : <String>[],
    bitis: _practiceExamSnapshotAsNum(data['bitis']),
    bitisDk: _practiceExamSnapshotAsNum(data['bitisDk']),
    participantCount: _practiceExamSnapshotAsNum(data['participantCount']),
    shortId: (data['shortId'] ?? '').toString(),
    shortUrl: (data['shortUrl'] ?? '').toString(),
  );
}

Future<List<SinavModel>> _fetchPracticeExamOwnerItems(
  PracticeExamOwnerQuery query,
) async {
  final normalizedUserId = query.userId.trim();
  if (normalizedUserId.isEmpty) return const <SinavModel>[];
  final snap = await FirebaseFirestore.instance
      .collection('practiceExams')
      .where('userID', isEqualTo: normalizedUserId)
      .get();
  final docs = snap.docs.toList(growable: false)
    ..sort((a, b) {
      final aTs = _practiceExamSnapshotAsNum(a.data()['timeStamp']).toInt();
      final bTs = _practiceExamSnapshotAsNum(b.data()['timeStamp']).toInt();
      return bTs.compareTo(aTs);
    });
  return docs
      .map((doc) => _practiceExamSnapshotFromDoc(doc.id, doc.data()))
      .toList(growable: false);
}

Future<List<SinavModel>> _fetchPracticeExamTypeItems(
  PracticeExamTypeQuery query,
) async {
  final normalizedExamType = query.examType.trim();
  if (normalizedExamType.isEmpty) return const <SinavModel>[];
  final snap = await FirebaseFirestore.instance
      .collection('practiceExams')
      .where('sinavTuru', isEqualTo: normalizedExamType)
      .limit(ReadBudgetRegistry.practiceExamTypeInitialLimit)
      .get();
  return snap.docs
      .map((doc) => _practiceExamSnapshotFromDoc(doc.id, doc.data()))
      .toList(growable: false);
}

Future<List<SinavModel>> _fetchPracticeExamAnsweredItems(
  PracticeExamAnsweredQuery query,
) async {
  final normalizedUserId = query.userId.trim();
  if (normalizedUserId.isEmpty) return const <SinavModel>[];
  final normalizedLimit = query.effectiveLimit;
  final answeredRefsSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(normalizedUserId)
      .collection('answered_practice_exams')
      .get(const GetOptions(source: Source.serverAndCache));

  final examDocIds = <String>{
    for (final refDoc in answeredRefsSnap.docs)
      if (refDoc.id.trim().isNotEmpty) refDoc.id.trim(),
  };

  if (examDocIds.isEmpty) {
    final yanitlarSnap = await FirebaseFirestore.instance
        .collectionGroup('Yanitlar')
        .where('userID', isEqualTo: normalizedUserId)
        .get(const GetOptions(source: Source.serverAndCache));

    final backfillEntries = <String, int>{};
    for (final yanitDoc in yanitlarSnap.docs) {
      final parentRef = yanitDoc.reference.parent.parent;
      if (parentRef == null || parentRef.parent.id != 'practiceExams') {
        continue;
      }
      final examDocId = parentRef.id.trim();
      if (examDocId.isEmpty) continue;
      examDocIds.add(examDocId);
      final rawTimestamp = yanitDoc.data()['timeStamp'];
      final timestamp = rawTimestamp is num ? rawTimestamp.toInt() : 0;
      final previous = backfillEntries[examDocId] ?? 0;
      if (timestamp > previous) {
        backfillEntries[examDocId] = timestamp;
      }
    }
    if (backfillEntries.isNotEmpty) {
      await _backfillAnsweredPracticeExamRefs(
        normalizedUserId,
        backfillEntries,
      );
    }
  }

  if (examDocIds.isEmpty) return const <SinavModel>[];

  final models = await ensurePracticeExamRepository().fetchByIds(
    examDocIds.toList(growable: false),
    preferCache: true,
    cacheOnly: false,
  );
  final sorted = models.toList(growable: false)
    ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
  return sorted.take(normalizedLimit).toList(growable: false);
}

Future<void> _backfillAnsweredPracticeExamRefs(
  String userId,
  Map<String, int> examTimestamps,
) async {
  final normalizedUserId = userId.trim();
  if (normalizedUserId.isEmpty || examTimestamps.isEmpty) return;

  final firestore = FirebaseFirestore.instance;
  final entries = examTimestamps.entries.toList(growable: false);
  for (var index = 0; index < entries.length; index += 200) {
    final batch = firestore.batch();
    final chunk = entries.skip(index).take(200);
    for (final entry in chunk) {
      final timestamp =
          entry.value > 0 ? entry.value : DateTime.now().millisecondsSinceEpoch;
      final ref = firestore
          .collection('users')
          .doc(normalizedUserId)
          .collection('answered_practice_exams')
          .doc(entry.key);
      batch.set(
          ref,
          <String, dynamic>{
            'practiceExamId': entry.key,
            'updatedDate': timestamp,
            'timeStamp': timestamp,
          },
          SetOptions(merge: true));
    }
    await batch.commit();
  }
}
