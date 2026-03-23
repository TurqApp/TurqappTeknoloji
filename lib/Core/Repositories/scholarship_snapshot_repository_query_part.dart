part of 'scholarship_snapshot_repository.dart';

extension ScholarshipSnapshotRepositoryQueryPart
    on ScholarshipSnapshotRepository {
  Stream<CachedResource<ScholarshipListingSnapshot>> _openHomeImpl({
    required String userId,
    required int limit,
    required int page,
    required bool forceSync,
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

  Future<CachedResource<ScholarshipListingSnapshot>> _loadHomeImpl({
    required String userId,
    required int limit,
    required int page,
    required bool forceSync,
  }) {
    return openHome(
      userId: userId,
      limit: limit,
      page: page,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<ScholarshipListingSnapshot>> _openSearchImpl({
    required String query,
    required String userId,
    required int limit,
    required int page,
    required bool forceSync,
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

  Future<CachedResource<ScholarshipListingSnapshot>> _searchImpl({
    required String query,
    required String userId,
    required int limit,
    required int page,
    required bool forceSync,
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
}
