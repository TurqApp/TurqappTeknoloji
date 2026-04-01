part of 'scholarship_snapshot_repository.dart';

extension ScholarshipSnapshotRepositoryQueryPart
    on ScholarshipSnapshotRepository {
  int _asScholarshipHitInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  String _asScholarshipHitString(Object? value) => (value ?? '').toString();

  List<String> _asScholarshipHitStringList(Object? value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return const <String>[];
  }

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
      'likesCount': _asScholarshipHitInt(hit['likeCount']),
      'bookmarksCount': _asScholarshipHitInt(hit['bookmarkCount']),
      'timeStamp': model.timeStamp,
      'isSummary': true,
    };
  }

  IndividualScholarshipsModel _buildModelFromHit(Map<String, dynamic> hit) {
    final cover = _asScholarshipHitString(hit['cover']).trim();
    return IndividualScholarshipsModel.fromJson(<String, dynamic>{
      'aciklama': _asScholarshipHitString(
        hit['aciklama'] ?? hit['description'],
      ),
      'shortDescription': _asScholarshipHitString(
        hit['shortDescription'],
      ).trim(),
      'altEgitimKitlesi': _asScholarshipHitStringList(hit['altEgitimKitlesi']),
      'aylar': _asScholarshipHitStringList(hit['aylar']),
      'basvurular': const <String>[],
      'baslangicTarihi': _asScholarshipHitString(hit['baslangicTarihi']),
      'baslik': _asScholarshipHitString(hit['title']),
      'basvuruKosullari': _asScholarshipHitString(hit['basvuruKosullari']),
      'basvuruURL': _asScholarshipHitString(hit['basvuruURL']),
      'basvuruYapilacakYer': _asScholarshipHitString(
        hit['basvuruYapilacakYer'],
      ),
      'begeniler': const <String>[],
      'belgeler': _asScholarshipHitStringList(hit['belgeler']),
      'bitisTarihi': _asScholarshipHitString(hit['bitisTarihi']),
      'bursVeren': _asScholarshipHitString(hit['bursVeren'] ?? hit['subtitle']),
      'egitimKitlesi': _asScholarshipHitString(hit['egitimKitlesi']),
      'geriOdemeli': _asScholarshipHitString(hit['geriOdemeli']),
      'goruntuleme': const <String>[],
      'hedefKitle': _asScholarshipHitString(hit['hedefKitle']),
      'ilceler': _asScholarshipHitStringList(hit['ilceler']),
      'img': cover,
      'img2': _asScholarshipHitString(hit['img2']),
      'kaydedenler': const <String>[],
      'kaydedilenler': const <String>[],
      'liseOrtaOkulIlceler': _asScholarshipHitStringList(
        hit['liseOrtaOkulIlceler'],
      ),
      'liseOrtaOkulSehirler': _asScholarshipHitStringList(
        hit['liseOrtaOkulSehirler'],
      ),
      'logo': _asScholarshipHitString(hit['logo'] ?? hit['logoUrl']).trim(),
      'mukerrerDurumu': _asScholarshipHitString(hit['mukerrerDurumu']),
      'ogrenciSayisi': _asScholarshipHitString(hit['ogrenciSayisi']),
      'sehirler': _asScholarshipHitStringList(hit['sehirler']),
      'timeStamp': _asScholarshipHitInt(hit['timeStamp']),
      'tutar': _asScholarshipHitString(hit['tutar']),
      'universiteler': _asScholarshipHitStringList(hit['universiteler']),
      'userID': _asScholarshipHitString(hit['ownerId'] ?? hit['userID']),
      'website': _asScholarshipHitString(hit['website']),
      'lisansTuru': _asScholarshipHitString(hit['lisansTuru']),
      'template': _asScholarshipHitString(hit['template']),
      'ulke': _asScholarshipHitString(hit['ulke'] ?? hit['country']),
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
