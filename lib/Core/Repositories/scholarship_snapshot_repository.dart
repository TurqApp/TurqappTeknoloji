import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/scholarship_constants.dart';

class ScholarshipListingSnapshot {
  const ScholarshipListingSnapshot({
    required this.items,
    required this.found,
  });

  final List<Map<String, dynamic>> items;
  final int found;
}

class ScholarshipSnapshotRepository extends GetxService {
  ScholarshipSnapshotRepository();

  static const String _homeSurfaceKey = 'scholarship_home_snapshot';
  static const String _searchSurfaceKey = 'scholarship_search_snapshot';

  static ScholarshipSnapshotRepository ensure() {
    if (Get.isRegistered<ScholarshipSnapshotRepository>()) {
      return Get.find<ScholarshipSnapshotRepository>();
    }
    return Get.put(ScholarshipSnapshotRepository(), permanent: true);
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  late final CacheFirstCoordinator<ScholarshipListingSnapshot> _coordinator =
      CacheFirstCoordinator<ScholarshipListingSnapshot>(
    memoryStore: MemoryScopedSnapshotStore<ScholarshipListingSnapshot>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<ScholarshipListingSnapshot>(
      prefsPrefix: 'scholarship_snapshot_v1',
      encode: _encodeSnapshot,
      decode: _decodeSnapshot,
    ),
    telemetry: const CacheFirstKpiTelemetry<ScholarshipListingSnapshot>(),
    policy: const CacheFirstPolicy(
      snapshotTtl: Duration(minutes: 20),
      minLiveSyncInterval: Duration(seconds: 30),
      syncOnOpen: true,
      allowWarmLaunchFallback: true,
      persistWarmLaunchSnapshot: true,
      treatWarmLaunchAsStale: true,
      preservePreviousOnEmptyLive: true,
    ),
  );

  late final EducationTypesenseCacheFirstAdapter<ScholarshipListingSnapshot>
      _homeAdapter =
      EducationTypesenseCacheFirstAdapter<ScholarshipListingSnapshot>(
    surfaceKey: _homeSurfaceKey,
    coordinator: _coordinator,
    resolve: _resolveHits,
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (snapshot) => snapshot.items.isEmpty,
  );

  late final EducationTypesenseCacheFirstAdapter<ScholarshipListingSnapshot>
      _searchAdapter =
      EducationTypesenseCacheFirstAdapter<ScholarshipListingSnapshot>(
    surfaceKey: _searchSurfaceKey,
    coordinator: _coordinator,
    resolve: _resolveHits,
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (snapshot) => snapshot.items.isEmpty,
  );

  Stream<CachedResource<ScholarshipListingSnapshot>> openHome({
    required String userId,
    int limit = 30,
    int page = 1,
    bool forceSync = false,
  }) {
    return _homeAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.scholarship,
        query: '*',
        limit: limit,
        page: page,
        userId: userId,
        scopeTag: page <= 1 ? 'home' : 'home_page_$page',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<ScholarshipListingSnapshot>> loadHome({
    required String userId,
    int limit = 30,
    int page = 1,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      limit: limit,
      page: page,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<ScholarshipListingSnapshot>> openSearch({
    required String query,
    required String userId,
    int limit = 40,
    int page = 1,
    bool forceSync = false,
  }) {
    return _searchAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.scholarship,
        query: query,
        limit: limit,
        page: page,
        userId: userId,
        scopeTag: page <= 1 ? 'search' : 'search_page_$page',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<ScholarshipListingSnapshot>> search({
    required String query,
    required String userId,
    int limit = 40,
    int page = 1,
    bool forceSync = false,
  }) {
    return openSearch(
      query: query,
      userId: userId,
      limit: limit,
      page: page,
      forceSync: forceSync,
    ).last;
  }

  Future<ScholarshipListingSnapshot?> _loadWarmSnapshot(
    EducationTypesenseQuery query,
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
    final resolved = _resolveHits(raw);
    return resolved.items.isEmpty ? null : resolved;
  }

  ScholarshipListingSnapshot _resolveHits(EducationTypesenseSearchResult raw) {
    final items = raw.hits
        .where(
          (hit) => ((hit['docId'] ?? hit['id'])?.toString().trim().isNotEmpty ??
              false),
        )
        .map(_buildCombinedItem)
        .toList(growable: false);
    return ScholarshipListingSnapshot(
      items: items,
      found: raw.found,
    );
  }

  Map<String, dynamic> _buildCombinedItem(Map<String, dynamic> hit) {
    final docId = ((hit['docId'] ?? hit['id']) ?? '').toString().trim();
    final userId = ((hit['ownerId'] ?? hit['userID']) ?? '').toString().trim();
    final model = _buildModelFromHit(hit);
    final userData = _buildUserDataFromHit(hit);
    if (userId.isNotEmpty) {
      final summary = _userSummaryResolver.resolveFromMaps(
        userId,
        embedded: userData,
      );
      unawaited(_userSummaryResolver.seedRaw(userId, summary.toMap()));
    }
    return <String, dynamic>{
      'model': model,
      'type': kIndividualScholarshipType,
      'userData': userData,
      'docId': docId,
      'likesCount': (hit['likeCount'] as num?)?.toInt() ?? 0,
      'bookmarksCount': (hit['bookmarkCount'] as num?)?.toInt() ?? 0,
      'timeStamp': model.timeStamp,
      'isSummary': true,
    };
  }

  IndividualScholarshipsModel _buildModelFromHit(Map<String, dynamic> hit) {
    final cover = (hit['cover'] ?? '').toString().trim();
    return IndividualScholarshipsModel.fromJson(<String, dynamic>{
      'aciklama': (hit['aciklama'] ?? hit['description'] ?? '').toString(),
      'shortDescription': (hit['shortDescription'] ?? '').toString().trim(),
      'altEgitimKitlesi': List<String>.from(
        (hit['altEgitimKitlesi'] as List<dynamic>? ?? const <dynamic>[]),
      ),
      'aylar': List<String>.from(
        (hit['aylar'] as List<dynamic>? ?? const <dynamic>[]),
      ),
      'basvurular': const <String>[],
      'baslangicTarihi': (hit['baslangicTarihi'] ?? '').toString(),
      'baslik': (hit['title'] ?? '').toString(),
      'basvuruKosullari': (hit['basvuruKosullari'] ?? '').toString(),
      'basvuruURL': (hit['basvuruURL'] ?? '').toString(),
      'basvuruYapilacakYer': (hit['basvuruYapilacakYer'] ?? '').toString(),
      'begeniler': const <String>[],
      'belgeler': List<String>.from(
        (hit['belgeler'] as List<dynamic>? ?? const <dynamic>[]),
      ),
      'bitisTarihi': (hit['bitisTarihi'] ?? '').toString(),
      'bursVeren': (hit['bursVeren'] ?? hit['subtitle'] ?? '').toString(),
      'egitimKitlesi': (hit['egitimKitlesi'] ?? '').toString(),
      'geriOdemeli': (hit['geriOdemeli'] ?? '').toString(),
      'goruntuleme': const <String>[],
      'hedefKitle': (hit['hedefKitle'] ?? '').toString(),
      'ilceler': List<String>.from(
        (hit['ilceler'] as List<dynamic>? ?? const <dynamic>[]),
      ),
      'img': cover,
      'img2': (hit['img2'] ?? '').toString(),
      'kaydedenler': const <String>[],
      'kaydedilenler': const <String>[],
      'liseOrtaOkulIlceler': List<String>.from(
        (hit['liseOrtaOkulIlceler'] as List<dynamic>? ?? const <dynamic>[]),
      ),
      'liseOrtaOkulSehirler': List<String>.from(
        (hit['liseOrtaOkulSehirler'] as List<dynamic>? ?? const <dynamic>[]),
      ),
      'logo': '',
      'mukerrerDurumu': (hit['mukerrerDurumu'] ?? '').toString(),
      'ogrenciSayisi': (hit['ogrenciSayisi'] ?? '').toString(),
      'sehirler': List<String>.from(
        (hit['sehirler'] as List<dynamic>? ?? const <dynamic>[]),
      ),
      'timeStamp': (hit['timeStamp'] as num?)?.toInt() ?? 0,
      'tutar': (hit['tutar'] ?? '').toString(),
      'universiteler': List<String>.from(
        (hit['universiteler'] as List<dynamic>? ?? const <dynamic>[]),
      ),
      'userID': ((hit['ownerId'] ?? hit['userID']) ?? '').toString(),
      'website': (hit['website'] ?? '').toString(),
      'lisansTuru': (hit['lisansTuru'] ?? '').toString(),
      'template': (hit['template'] ?? '').toString(),
      'ulke': (hit['ulke'] ?? hit['country'] ?? '').toString(),
    });
  }

  Map<String, dynamic> _buildUserDataFromHit(Map<String, dynamic> hit) {
    final userId = ((hit['ownerId'] ?? hit['userID']) ?? '').toString().trim();
    final summary = _userSummaryResolver.resolveFromMaps(
      userId,
      embedded: <String, dynamic>{
        'nickname': hit['nickname'] ?? hit['authorNickname'],
        'displayName': hit['displayName'] ?? hit['authorDisplayName'],
        'avatarUrl': hit['avatarUrl'] ?? hit['authorAvatarUrl'],
        'rozet': hit['rozet'] ?? hit['badge'],
        'userID': userId,
      },
    );
    return <String, dynamic>{
      'avatarUrl': summary.avatarUrl,
      'nickname': summary.nickname,
      'displayName': summary.displayName.isNotEmpty
          ? summary.displayName
          : summary.nickname,
      'rozet': summary.rozet,
      'userID': summary.userID,
    };
  }

  Map<String, dynamic> _encodeSnapshot(ScholarshipListingSnapshot snapshot) {
    return <String, dynamic>{
      'found': snapshot.found,
      'items': snapshot.items.map(_encodeCombinedItem).toList(growable: false),
    };
  }

  ScholarshipListingSnapshot _decodeSnapshot(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
    return ScholarshipListingSnapshot(
      items: rawItems
          .whereType<Map>()
          .map(
            (raw) =>
                _decodeCombinedItem(Map<String, dynamic>.from(raw.cast())),
          )
          .where((item) => (item['docId'] ?? '').toString().isNotEmpty)
          .toList(growable: false),
      found: (json['found'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> _encodeCombinedItem(Map<String, dynamic> item) {
    final model = item['model'] as IndividualScholarshipsModel;
    return <String, dynamic>{
      'docId': item['docId'] ?? '',
      'type': item['type'] ?? kIndividualScholarshipType,
      'model': model.toJson(),
      'userData': Map<String, dynamic>.from(item['userData'] as Map? ?? const {}),
      'likesCount': item['likesCount'] ?? 0,
      'bookmarksCount': item['bookmarksCount'] ?? 0,
      'timeStamp': item['timeStamp'] ?? model.timeStamp,
      'isSummary': item['isSummary'] ?? false,
    };
  }

  Map<String, dynamic> _decodeCombinedItem(Map<String, dynamic> item) {
    final modelMap = Map<String, dynamic>.from(item['model'] as Map? ?? const {});
    return <String, dynamic>{
      'model': IndividualScholarshipsModel.fromJson(modelMap),
      'type': (item['type'] ?? kIndividualScholarshipType).toString(),
      'userData': Map<String, dynamic>.from(item['userData'] as Map? ?? const {}),
      'docId': (item['docId'] ?? '').toString(),
      'likesCount': (item['likesCount'] as num?)?.toInt() ?? 0,
      'bookmarksCount': (item['bookmarksCount'] as num?)?.toInt() ?? 0,
      'timeStamp': (item['timeStamp'] as num?)?.toInt() ?? 0,
      'isSummary': item['isSummary'] == true,
    };
  }
}
