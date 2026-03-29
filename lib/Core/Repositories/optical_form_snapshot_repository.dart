import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
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

  Future<CachedResource<List<OpticalFormModel>>> loadCachedOwner({
    required String userId,
  }) {
    final query = OpticalFormOwnerQuery(userId: userId);
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
    final snapshot = await FirebaseFirestore.instance
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
}
