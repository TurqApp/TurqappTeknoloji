import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class TestOwnerQuery {
  const TestOwnerQuery({
    required this.userId,
  });

  final String userId;

  String buildScopeId() => CacheScopeNamespace.buildQueryScope(
        userId: userId,
        limit: 0,
        scopeTag: 'owner',
        schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
          TestSnapshotRepository.ownerSurfaceKey,
        ),
        qualifiers: <String, Object?>{
          'owner': userId.trim(),
        },
      );
}

class TestAllQuery {
  const TestAllQuery({
    required this.userId,
  });

  final String userId;

  String buildScopeId() => CacheScopeNamespace.buildQueryScope(
        userId: userId,
        limit: 0,
        scopeTag: 'home',
        schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
          TestSnapshotRepository.allSurfaceKey,
        ),
        qualifiers: const <String, Object?>{
          'all': true,
        },
      );
}

class TestTypeQuery {
  const TestTypeQuery({
    required this.userId,
    required this.testType,
  });

  final String userId;
  final String testType;

  String buildScopeId() => CacheScopeNamespace.buildQueryScope(
        userId: userId,
        limit: 0,
        scopeTag: 'type',
        schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
          TestSnapshotRepository.typeSurfaceKey,
        ),
        qualifiers: <String, Object?>{
          'type': testType.trim(),
        },
      );
}

class TestAnsweredQuery {
  const TestAnsweredQuery({
    required this.userId,
    required this.limit,
  });

  final String userId;
  final int limit;

  int get effectiveLimit =>
      ReadBudgetRegistry.resolveTestAnsweredInitialLimit(limit);

  String buildScopeId() => CacheScopeNamespace.buildQueryScope(
        userId: userId,
        limit: effectiveLimit,
        scopeTag: 'answered',
        schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
          TestSnapshotRepository.answeredSurfaceKey,
        ),
        qualifiers: <String, Object?>{
          'answered': userId.trim(),
          'limit': effectiveLimit,
        },
      );
}

class TestFavoritesQuery {
  const TestFavoritesQuery({
    required this.userId,
    required this.limit,
  });

  final String userId;
  final int limit;

  int get effectiveLimit =>
      ReadBudgetRegistry.resolveTestFavoritesInitialLimit(limit);

  String buildScopeId() => CacheScopeNamespace.buildQueryScope(
        userId: userId,
        limit: effectiveLimit,
        scopeTag: 'favorites',
        schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
          TestSnapshotRepository.favoritesSurfaceKey,
        ),
        qualifiers: <String, Object?>{
          'favorites': userId.trim(),
          'limit': effectiveLimit,
        },
      );
}

class TestSharedPageQuery {
  const TestSharedPageQuery({
    required this.userId,
    required this.page,
    required this.limit,
  });

  final String userId;
  final int page;
  final int limit;

  String buildScopeId() => CacheScopeNamespace.buildQueryScope(
        userId: userId,
        limit: limit,
        scopeTag: page <= 1 ? 'shared' : 'shared_page_$page',
        schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
          TestSnapshotRepository.sharedSurfaceKey,
        ),
        qualifiers: <String, Object?>{
          'shared': true,
          'page': page,
          'limit': limit,
        },
      );
}

TestSnapshotRepository? maybeFindTestSnapshotRepository() {
  final isRegistered = Get.isRegistered<TestSnapshotRepository>();
  if (!isRegistered) return null;
  return Get.find<TestSnapshotRepository>();
}

TestSnapshotRepository ensureTestSnapshotRepository() {
  final existing = maybeFindTestSnapshotRepository();
  if (existing != null) return existing;
  return Get.put(TestSnapshotRepository(), permanent: true);
}

class TestSnapshotRepository extends GetxService {
  TestSnapshotRepository();

  static const String ownerSurfaceKey = 'test_owner_snapshot';
  static const String allSurfaceKey = 'test_home_snapshot';
  static const String typeSurfaceKey = 'test_type_snapshot';
  static const String answeredSurfaceKey = 'test_answered_snapshot';
  static const String favoritesSurfaceKey = 'test_favorites_snapshot';
  static const String sharedSurfaceKey = 'test_shared_snapshot';

  late final CacheFirstCoordinator<List<TestsModel>> _coordinator =
      CacheFirstCoordinator<List<TestsModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<TestsModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<TestsModel>>(
      prefsPrefix: 'test_snapshot_v1',
      encode: _encodeItems,
      decode: _decodeItems,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<TestsModel>>(),
    policy: CacheFirstPolicyRegistry.policyForSurface(ownerSurfaceKey),
  );

  late final CacheFirstQueryPipeline<TestOwnerQuery, List<TestsModel>,
          List<TestsModel>> _ownerPipeline =
      CacheFirstQueryPipeline<TestOwnerQuery, List<TestsModel>,
          List<TestsModel>>(
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

  late final CacheFirstQueryPipeline<TestAllQuery, List<TestsModel>,
          List<TestsModel>> _allPipeline =
      CacheFirstQueryPipeline<TestAllQuery, List<TestsModel>, List<TestsModel>>(
    surfaceKey: allSurfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.buildScopeId(),
    fetchRaw: _fetchAllItems,
    resolve: (items) => items,
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      allSurfaceKey,
    ),
  );

  late final CacheFirstQueryPipeline<TestTypeQuery, List<TestsModel>,
          List<TestsModel>> _typePipeline =
      CacheFirstQueryPipeline<TestTypeQuery, List<TestsModel>,
          List<TestsModel>>(
    surfaceKey: typeSurfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.buildScopeId(),
    fetchRaw: _fetchTypeItems,
    resolve: (items) => items,
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      typeSurfaceKey,
    ),
  );

  late final CacheFirstQueryPipeline<TestAnsweredQuery, List<TestsModel>,
          List<TestsModel>> _answeredPipeline =
      CacheFirstQueryPipeline<TestAnsweredQuery, List<TestsModel>,
          List<TestsModel>>(
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

  late final CacheFirstQueryPipeline<TestFavoritesQuery, List<TestsModel>,
          List<TestsModel>> _favoritesPipeline =
      CacheFirstQueryPipeline<TestFavoritesQuery, List<TestsModel>,
          List<TestsModel>>(
    surfaceKey: favoritesSurfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.buildScopeId(),
    fetchRaw: _fetchFavoriteItems,
    resolve: (items) => items,
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      favoritesSurfaceKey,
    ),
  );

  late final CacheFirstQueryPipeline<TestSharedPageQuery, List<TestsModel>,
          List<TestsModel>> _sharedPipeline =
      CacheFirstQueryPipeline<TestSharedPageQuery, List<TestsModel>,
          List<TestsModel>>(
    surfaceKey: sharedSurfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.buildScopeId(),
    fetchRaw: _fetchSharedPageItems,
    resolve: (items) => items,
    isEmpty: (items) => items.isEmpty,
    liveSource: CachedResourceSource.server,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      sharedSurfaceKey,
    ),
  );

  Future<CachedResource<List<TestsModel>>> loadCachedOwner({
    required String userId,
  }) {
    final query = TestOwnerQuery(userId: userId);
    return _bootstrap(
      surfaceKey: ownerSurfaceKey,
      userId: userId,
      scopeId: query.buildScopeId(),
    );
  }

  Future<CachedResource<List<TestsModel>>> loadCachedAll({
    required String userId,
  }) {
    final query = TestAllQuery(userId: userId);
    return _bootstrap(
      surfaceKey: allSurfaceKey,
      userId: userId,
      scopeId: query.buildScopeId(),
    );
  }

  Future<CachedResource<List<TestsModel>>> loadCachedType({
    required String userId,
    required String testType,
  }) {
    final query = TestTypeQuery(
      userId: userId,
      testType: testType,
    );
    return _bootstrap(
      surfaceKey: typeSurfaceKey,
      userId: userId,
      scopeId: query.buildScopeId(),
    );
  }

  Future<CachedResource<List<TestsModel>>> loadCachedAnswered({
    required String userId,
    int limit = ReadBudgetRegistry.testAnsweredInitialLimit,
  }) {
    final effectiveLimit =
        ReadBudgetRegistry.resolveTestAnsweredInitialLimit(limit);
    final query = TestAnsweredQuery(
      userId: userId,
      limit: effectiveLimit,
    );
    return _bootstrap(
      surfaceKey: answeredSurfaceKey,
      userId: userId,
      scopeId: query.buildScopeId(),
    );
  }

  Future<CachedResource<List<TestsModel>>> loadCachedFavorites({
    required String userId,
    int limit = ReadBudgetRegistry.testFavoritesInitialLimit,
  }) {
    final effectiveLimit =
        ReadBudgetRegistry.resolveTestFavoritesInitialLimit(limit);
    final query = TestFavoritesQuery(
      userId: userId,
      limit: effectiveLimit,
    );
    return _bootstrap(
      surfaceKey: favoritesSurfaceKey,
      userId: userId,
      scopeId: query.buildScopeId(),
    );
  }

  Future<CachedResource<List<TestsModel>>> loadCachedSharedPage({
    required String userId,
    int page = 1,
    int limit = ReadBudgetRegistry.testSharedPageLimit,
  }) {
    final query = TestSharedPageQuery(
      userId: userId,
      page: page,
      limit: limit,
    );
    return _bootstrap(
      surfaceKey: sharedSurfaceKey,
      userId: userId,
      scopeId: query.buildScopeId(),
    );
  }

  Future<CachedResource<List<TestsModel>>> _bootstrap({
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

  Stream<CachedResource<List<TestsModel>>> openOwner({
    required String userId,
    bool forceSync = false,
  }) {
    return _ownerPipeline.open(
      TestOwnerQuery(userId: userId),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<TestsModel>>> loadOwner({
    required String userId,
    bool forceSync = false,
  }) {
    return openOwner(
      userId: userId,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<TestsModel>>> openAll({
    required String userId,
    bool forceSync = false,
  }) {
    return _allPipeline.open(
      TestAllQuery(userId: userId),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<TestsModel>>> loadAll({
    required String userId,
    bool forceSync = false,
  }) {
    return openAll(
      userId: userId,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<TestsModel>>> openType({
    required String userId,
    required String testType,
    bool forceSync = false,
  }) {
    return _typePipeline.open(
      TestTypeQuery(
        userId: userId,
        testType: testType,
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<TestsModel>>> loadType({
    required String userId,
    required String testType,
    bool forceSync = false,
  }) {
    return openType(
      userId: userId,
      testType: testType,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<TestsModel>>> openAnswered({
    required String userId,
    int limit = ReadBudgetRegistry.testAnsweredInitialLimit,
    bool forceSync = false,
  }) {
    final effectiveLimit =
        ReadBudgetRegistry.resolveTestAnsweredInitialLimit(limit);
    return _answeredPipeline.open(
      TestAnsweredQuery(
        userId: userId,
        limit: effectiveLimit,
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<TestsModel>>> loadAnswered({
    required String userId,
    int limit = ReadBudgetRegistry.testAnsweredInitialLimit,
    bool forceSync = false,
  }) {
    return openAnswered(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<TestsModel>>> openFavorites({
    required String userId,
    int limit = ReadBudgetRegistry.testFavoritesInitialLimit,
    bool forceSync = false,
  }) {
    final effectiveLimit =
        ReadBudgetRegistry.resolveTestFavoritesInitialLimit(limit);
    return _favoritesPipeline.open(
      TestFavoritesQuery(
        userId: userId,
        limit: effectiveLimit,
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<TestsModel>>> loadFavorites({
    required String userId,
    int limit = ReadBudgetRegistry.testFavoritesInitialLimit,
    bool forceSync = false,
  }) {
    return openFavorites(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<TestsModel>>> openSharedPage({
    required String userId,
    int page = 1,
    int limit = ReadBudgetRegistry.testSharedPageLimit,
    bool forceSync = false,
  }) {
    return _sharedPipeline.open(
      TestSharedPageQuery(
        userId: userId,
        page: page,
        limit: limit,
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<TestsModel>>> loadSharedPage({
    required String userId,
    int page = 1,
    int limit = ReadBudgetRegistry.testSharedPageLimit,
    bool forceSync = false,
  }) {
    return openSharedPage(
      userId: userId,
      page: page,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Map<String, dynamic> _encodeItems(List<TestsModel> items) {
    return <String, dynamic>{
      'items': items
          .map(
            (item) => <String, dynamic>{
              'docID': item.docID,
              'userID': item.userID,
              'timeStamp': item.timeStamp,
              'aciklama': item.aciklama,
              'dersler': List<String>.from(item.dersler, growable: false),
              'img': item.img,
              'paylasilabilir': item.paylasilabilir,
              'testTuru': item.testTuru,
              'taslak': item.taslak,
            },
          )
          .toList(growable: false),
    };
  }

  List<TestsModel> _decodeItems(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
    return rawItems
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
          return TestsModel(
            userID: (item['userID'] ?? '').toString(),
            timeStamp: (item['timeStamp'] ?? '').toString(),
            aciklama: (item['aciklama'] ?? '').toString(),
            dersler: ((item['dersler'] as List<dynamic>?) ?? const [])
                .map((lesson) => lesson.toString())
                .where((lesson) => lesson.trim().isNotEmpty)
                .toList(growable: false),
            img: (item['img'] ?? '').toString(),
            docID: (item['docID'] ?? '').toString(),
            paylasilabilir: item['paylasilabilir'] == true,
            testTuru: (item['testTuru'] ?? '').toString(),
            taslak: item['taslak'] == true,
          );
        })
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false);
  }

  int _asTimestamp(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 0;
    final parsed = int.tryParse(normalized);
    if (parsed != null) return parsed;
    final parsedNum = num.tryParse(normalized);
    if (parsedNum != null) return parsedNum.toInt();
    return 0;
  }

  TestsModel _fromDoc(String id, Map<String, dynamic> data) {
    return TestsModel(
      userID: (data['userID'] ?? '').toString(),
      timeStamp: (data['timeStamp'] ?? '').toString(),
      aciklama: (data['aciklama'] ?? '').toString(),
      dersler: (data['dersler'] is List)
          ? (data['dersler'] as List).map((item) => item.toString()).toList()
          : <String>[],
      img: (data['img'] ?? '').toString(),
      docID: id,
      paylasilabilir: data['paylasilabilir'] == true,
      testTuru: (data['testTuru'] ?? '').toString(),
      taslak: data['taslak'] == true,
    );
  }

  Future<List<TestsModel>> _fetchOwnerItems(TestOwnerQuery query) async {
    final normalizedUserId = query.userId.trim();
    if (normalizedUserId.isEmpty) return const <TestsModel>[];
    final snapshot = await FirebaseFirestore.instance
        .collection('Testler')
        .where('userID', isEqualTo: normalizedUserId)
        .get(const GetOptions(source: Source.serverAndCache));
    final items = snapshot.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => _asTimestamp(b.timeStamp).compareTo(
            _asTimestamp(a.timeStamp),
          ));
    return items;
  }

  Future<List<TestsModel>> _fetchAllItems(TestAllQuery query) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Testler')
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<TestsModel>> _fetchTypeItems(TestTypeQuery query) async {
    final normalizedType = query.testType.trim();
    if (normalizedType.isEmpty) {
      return const <TestsModel>[];
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('Testler')
        .where('testTuru', isEqualTo: normalizedType)
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<TestsModel>> _fetchAnsweredItems(TestAnsweredQuery query) async {
    final normalizedUserId = query.userId.trim();
    if (normalizedUserId.isEmpty) return const <TestsModel>[];
    final normalizedLimit = query.effectiveLimit;
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('Yanitlar')
        .where('userID', isEqualTo: normalizedUserId)
        .get(const GetOptions(source: Source.serverAndCache));
    final testIds = <String>[];
    final seen = <String>{};
    for (final doc in snapshot.docs) {
      final parent = doc.reference.parent.parent;
      final testId = parent?.id ?? '';
      if (testId.isEmpty || !seen.add(testId)) continue;
      testIds.add(testId);
    }
    final items = await _fetchByIds(testIds);
    items.sort(
      (a, b) => _asTimestamp(b.timeStamp).compareTo(_asTimestamp(a.timeStamp)),
    );
    return items.take(normalizedLimit).toList(growable: false);
  }

  Future<List<TestsModel>> _fetchFavoriteItems(TestFavoritesQuery query) async {
    final normalizedUserId = query.userId.trim();
    if (normalizedUserId.isEmpty) return const <TestsModel>[];
    final normalizedLimit = query.effectiveLimit;
    final snapshot = await FirebaseFirestore.instance
        .collection('Testler')
        .where('favoriler', arrayContains: normalizedUserId)
        .get(const GetOptions(source: Source.serverAndCache));
    final items = snapshot.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false);
    items.sort(
      (a, b) => _asTimestamp(b.timeStamp).compareTo(_asTimestamp(a.timeStamp)),
    );
    return items.take(normalizedLimit).toList(growable: false);
  }

  Future<List<TestsModel>> _fetchSharedPageItems(
      TestSharedPageQuery query) async {
    final normalizedPage = query.page < 1 ? 1 : query.page;
    final normalizedLimit =
        query.limit < 1 ? ReadBudgetRegistry.testSharedPageLimit : query.limit;
    Query<Map<String, dynamic>> firestoreQuery = FirebaseFirestore.instance
        .collection('Testler')
        .where('paylasilabilir', isEqualTo: true)
        .orderBy('timeStamp', descending: true)
        .limit(normalizedLimit);

    DocumentSnapshot<Map<String, dynamic>>? cursor;
    for (var currentPage = 1; currentPage < normalizedPage; currentPage++) {
      final snapshot = await (cursor == null
              ? firestoreQuery
              : firestoreQuery.startAfterDocument(cursor))
          .get(const GetOptions(source: Source.serverAndCache));
      if (snapshot.docs.isEmpty || snapshot.docs.length < normalizedLimit) {
        return const <TestsModel>[];
      }
      cursor = snapshot.docs.last;
    }

    final snapshot = await (cursor == null
            ? firestoreQuery
            : firestoreQuery.startAfterDocument(cursor))
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<TestsModel>> _fetchByIds(List<String> ids) async {
    final wanted = ids.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (wanted.isEmpty) return const <TestsModel>[];
    final resolved = <String, TestsModel>{};
    for (final chunkStart in <int>[
      for (var i = 0; i < wanted.length; i += 10) i,
    ]) {
      final chunk = wanted.skip(chunkStart).take(10).toList(growable: false);
      final snapshot = await FirebaseFirestore.instance
          .collection('Testler')
          .where(FieldPath.documentId, whereIn: chunk)
          .get(const GetOptions(source: Source.serverAndCache));
      for (final doc in snapshot.docs) {
        resolved[doc.id] = _fromDoc(doc.id, doc.data());
      }
    }
    return wanted
        .map((id) => resolved[id])
        .whereType<TestsModel>()
        .toList(growable: false);
  }
}
