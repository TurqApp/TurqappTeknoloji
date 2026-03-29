import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
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

  Future<CachedResource<List<TestsModel>>> loadCachedOwner({
    required String userId,
  }) {
    final query = TestOwnerQuery(userId: userId);
    final key = ScopedSnapshotKey(
      surfaceKey: ownerSurfaceKey,
      userId: userId.trim(),
      scopeId: query.buildScopeId(),
    );
    return _coordinator.bootstrap(
      key,
      schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
        ownerSurfaceKey,
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
}
