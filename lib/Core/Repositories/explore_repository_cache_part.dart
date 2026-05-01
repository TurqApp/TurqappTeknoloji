part of 'explore_repository.dart';

const String _floodManifestStorePrefsKey = 'explore_flood_manifest_store_v1';
const int _floodManifestStoreRefreshIntervalMs = 24 * 60 * 60 * 1000;
const int _floodManifestStoreWarmRoots = 10;
const int _floodManifestStoreWarmImagesPerRoot = 4;
const int _floodManifestStoreWarmReadySegments = 2;

class _StoredFloodManifest {
  const _StoredFloodManifest({
    required this.savedAtMs,
    required this.updatedAtMs,
    required this.generatedAtMs,
    required this.rootCount,
    required this.items,
  });

  final int savedAtMs;
  final int updatedAtMs;
  final int generatedAtMs;
  final int rootCount;
  final List<Map<String, dynamic>> items;
}

extension ExploreRepositoryCachePart on ExploreRepository {
  Future<SharedPreferences> _prefsInstance() async {
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
    return _prefs!;
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      final parsed = int.tryParse(trimmed);
      if (parsed != null) return parsed;
      final parsedNum = num.tryParse(trimmed);
      if (parsedNum != null) return parsedNum.toInt();
    }
    return fallback;
  }

  String _normalizeFloodRootId(String anyFloodId) {
    final normalized = anyFloodId.trim();
    if (normalized.isEmpty) return '';
    return '${normalized.replaceFirst(RegExp(r'_\d+$'), '')}_0';
  }

  Map<String, dynamic> _normalizeFloodManifestDoc(
    Map<String, dynamic> raw,
    String docId,
  ) {
    final data = Map<String, dynamic>.from(raw);
    data['_manifestDocId'] = docId;
    final mainPostId = (data['mainPostId'] ?? docId).toString().trim();
    if (mainPostId.isNotEmpty) {
      data['mainPostId'] = mainPostId;
    }
    final floodRootId =
        (data['floodRootId'] ?? data['mainPostId'] ?? docId).toString().trim();
    if (floodRootId.isNotEmpty) {
      data['floodRootId'] = floodRootId;
    }
    return data;
  }

  Future<_StoredFloodManifest?> _readStoredFloodManifest() async {
    final prefs = await _prefsInstance();
    final raw = prefs.getString(_floodManifestStorePrefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedRaw = jsonDecode(raw);
      if (decodedRaw is! Map) {
        await prefs.remove(_floodManifestStorePrefsKey);
        return null;
      }
      final decoded = Map<String, dynamic>.from(
        decodedRaw.cast<dynamic, dynamic>(),
      );
      final savedAtMs = _asInt(decoded['savedAtMs']);
      final updatedAtMs = _asInt(decoded['updatedAtMs']);
      final generatedAtMs = _asInt(decoded['generatedAtMs']);
      final rootCount = _asInt(decoded['rootCount']);
      final rawItems = decoded['items'];
      if (savedAtMs <= 0 || rawItems is! List) {
        await prefs.remove(_floodManifestStorePrefsKey);
        return null;
      }
      final items = rawItems
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(
              item.cast<dynamic, dynamic>(),
            ),
          )
          .toList(growable: false);
      return _StoredFloodManifest(
        savedAtMs: savedAtMs,
        updatedAtMs: updatedAtMs,
        generatedAtMs: generatedAtMs,
        rootCount: rootCount,
        items: items,
      );
    } catch (_) {
      await prefs.remove(_floodManifestStorePrefsKey);
      return null;
    }
  }

  Future<void> _writeStoredFloodManifest({
    required int updatedAtMs,
    required int generatedAtMs,
    required int rootCount,
    required List<Map<String, dynamic>> items,
  }) async {
    final prefs = await _prefsInstance();
    await prefs.setString(
      _floodManifestStorePrefsKey,
      jsonEncode(<String, dynamic>{
        'savedAtMs': DateTime.now().millisecondsSinceEpoch,
        'updatedAtMs': updatedAtMs,
        'generatedAtMs': generatedAtMs,
        'rootCount': rootCount,
        'items': items,
      }),
    );
  }

  Iterable<Map<String, dynamic>> _floodManifestChildMaps(
    Map<String, dynamic> item,
  ) sync* {
    final children = item['children'];
    if (children is! List) return;
    for (final entry in children) {
      if (entry is! Map) continue;
      yield Map<String, dynamic>.from(entry.cast<dynamic, dynamic>());
    }
  }

  PostsModel? _floodManifestPostModelFromMap(
    Map<String, dynamic> data,
    String fallbackDocId,
  ) {
    final docId = (data['docId'] ?? data['mainPostId'] ?? data['floodRootId'] ?? fallbackDocId)
        .toString()
        .trim();
    if (docId.isEmpty) return null;
    try {
      return PostsModel.fromMap(data, docId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _warmFloodManifestMedia(
    List<Map<String, dynamic>> items,
  ) async {
    if (items.isEmpty) return;
    final scheduler = maybeFindPrefetchScheduler();
    final warmedImageUrls = <String>{};
    final warmedVideoDocIds = <String>{};

    for (final item in items.take(_floodManifestStoreWarmRoots)) {
      final rootModel = _floodManifestPostModelFromMap(
        item,
        (item['_manifestDocId'] ?? '').toString().trim(),
      );
      if (rootModel == null) continue;

      final seriesModels = <PostsModel>[rootModel];
      for (final child in _floodManifestChildMaps(item)) {
        final model = _floodManifestPostModelFromMap(child, rootModel.docID);
        if (model != null) {
          seriesModels.add(model);
        }
      }

      final imageUrls = <String>[];
      for (final model in seriesModels) {
        for (final url in <String>[
          ...model.preferredVideoPosterUrls,
          ...model.cdnImgUrls,
        ]) {
          final normalized = url.trim();
          if (normalized.isEmpty || !warmedImageUrls.add(normalized)) continue;
          imageUrls.add(normalized);
          if (imageUrls.length >= _floodManifestStoreWarmImagesPerRoot) {
            break;
          }
        }
        if (imageUrls.length >= _floodManifestStoreWarmImagesPerRoot) {
          break;
        }
      }

      for (final url in imageUrls) {
        try {
          await TurqImageCacheManager.warmUrl(url);
        } catch (_) {}
      }

      if (scheduler == null) continue;
      for (final model in seriesModels) {
        if (!model.hasPlayableVideo) continue;
        if (!warmedVideoDocIds.add(model.docID)) continue;
        try {
          scheduler.boostDoc(
            model.docID,
            readySegments: _floodManifestStoreWarmReadySegments,
          );
        } catch (_) {}
      }
    }
  }

  Future<ExploreQueryPage> _fetchStoredFloodManifestPage({
    required int offset,
    required int pageLimit,
    int? nowMs,
  }) async {
    final stored = await _readStoredFloodManifest();
    if (stored == null || stored.items.isEmpty) {
      debugPrint('[FloodManifestStore] status=miss scope=page offset=$offset');
      return const ExploreQueryPage(<PostsModel>[], null, false);
    }
    final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final filtered = stored.items
        .map((item) {
          final kind = (item['kind'] ?? '').toString().trim();
          final eligible = item['eligible'] == true;
          if (kind != 'flood' || !eligible) return null;
          final mainPostId = (item['mainPostId'] ??
                  item['floodRootId'] ??
                  item['_manifestDocId'])
              .toString()
              .trim();
          if (mainPostId.isEmpty) return null;
          try {
            return PostsModel.fromMap(item, mainPostId);
          } catch (_) {
            return null;
          }
        })
        .whereType<PostsModel>()
        .where((item) => !item.shouldHideWhileUploading)
        .where((item) => item.floodCount > 1)
        .where((item) => item.timeStamp <= ts)
        .toList(growable: false);
    if (offset >= filtered.length) {
      debugPrint(
        '[FloodManifestStore] status=exhausted scope=page offset=$offset total=${filtered.length}',
      );
      return const ExploreQueryPage(<PostsModel>[], null, false);
    }
    final end = (offset + pageLimit).clamp(0, filtered.length);
    final pageItems = filtered.sublist(offset, end);
    debugPrint(
      '[FloodManifestStore] status=hit scope=page offset=$offset returned=${pageItems.length} total=${filtered.length} hasMore=${end < filtered.length}',
    );
    return ExploreQueryPage(
      pageItems,
      null,
      end < filtered.length,
    );
  }

  Future<void> _ensureFloodManifestStoreFresh({bool force = false}) async {
    final stored = await _readStoredFloodManifest();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final shouldRefresh = force ||
        stored == null ||
        stored.items.isEmpty ||
        (nowMs - stored.savedAtMs) >= _floodManifestStoreRefreshIntervalMs;
    if (!shouldRefresh) {
      debugPrint(
        '[FloodManifestStore] status=refresh_skip reason=local_fresh savedAtMs=${stored.savedAtMs}',
      );
      return;
    }
    debugPrint(
      '[FloodManifestStore] status=refresh_start force=$force reason=daily_sync',
    );
    try {
      final callable = AppCloudFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('f30_getFloodManifestCallable');
      final response = await callable.call(<String, dynamic>{});
      final raw = response.data;
      if (raw is! Map) {
        debugPrint(
            '[FloodManifestStore] status=refresh_fail reason=invalid_payload');
        return;
      }
      final payload = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
      final updatedAtMs = _asInt(payload['updatedAtMs']);
      final generatedAtMs = _asInt(
        payload['generatedAt'],
        fallback: _asInt(payload['publishedAt']),
      );
      final rawItems = payload['items'];
      if (rawItems is! List || rawItems.isEmpty) {
        debugPrint(
            '[FloodManifestStore] status=refresh_fail reason=empty_items');
        return;
      }
      final items = rawItems
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(
              item.cast<dynamic, dynamic>(),
            ),
          )
          .map((item) {
        final docId =
            (item['floodRootId'] ?? item['mainPostId'] ?? '').toString().trim();
        return _normalizeFloodManifestDoc(item, docId);
      }).where((item) {
        final docId = (item['_manifestDocId'] ?? '').toString().trim();
        return docId.isNotEmpty;
      }).toList(growable: false);
      if (items.isEmpty) {
        debugPrint(
            '[FloodManifestStore] status=refresh_fail reason=normalized_empty');
        return;
      }
      final trimmedItems = items.toList(growable: false);
      await _writeStoredFloodManifest(
        updatedAtMs: updatedAtMs,
        generatedAtMs: generatedAtMs,
        rootCount: trimmedItems.length,
        items: trimmedItems,
      );
      unawaited(_warmFloodManifestMedia(trimmedItems));
      debugPrint(
        '[FloodManifestStore] status=refresh_ok roots=${trimmedItems.length} updatedAtMs=$updatedAtMs',
      );
    } catch (e) {
      debugPrint('[FloodManifestStore] status=refresh_fail error=$e');
    }
  }

  Future<int> _ensureFloodManifestStoreReady({
    bool force = false,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final existing = await _readStoredFloodManifest();
    final existingCount = existing?.items.length ?? 0;
    if (!force && existingCount > 0) {
      debugPrint(
        '[FloodManifestStore] status=ready_cached roots=$existingCount updatedAtMs=${existing?.updatedAtMs ?? 0}',
      );
      unawaited(_ensureFloodManifestStoreFresh());
      return existingCount;
    }
    try {
      await _ensureFloodManifestStoreFresh(force: force).timeout(timeout);
    } catch (e) {
      debugPrint(
        '[FloodManifestStore] status=ready_timeout force=$force timeoutMs=${timeout.inMilliseconds} error=$e',
      );
    }
    final stored = await _readStoredFloodManifest();
    return stored?.items.length ?? 0;
  }

  Future<List<PostsModel>> _loadStoredFloodManifestSeries(
      String anyFloodId) async {
    final stored = await _readStoredFloodManifest();
    if (stored == null || stored.items.isEmpty) {
      debugPrint(
          '[FloodManifestStore] status=series_miss scope=store root=$anyFloodId');
      return const <PostsModel>[];
    }
    final rootId = _normalizeFloodRootId(anyFloodId);
    if (rootId.isEmpty) return const <PostsModel>[];
    Map<String, dynamic>? match;
    for (final item in stored.items) {
      final manifestId = (item['_manifestDocId'] ?? '').toString().trim();
      final floodRootId =
          (item['floodRootId'] ?? item['mainPostId'] ?? '').toString().trim();
      if (manifestId == rootId || floodRootId == rootId) {
        match = item;
        break;
      }
    }
    if (match == null) return const <PostsModel>[];
    final kind = (match['kind'] ?? '').toString().trim();
    final eligible = match['eligible'] == true;
    if (kind != 'flood' || !eligible) {
      return const <PostsModel>[];
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final items = <PostsModel>[];
    try {
      final rootModel = PostsModel.fromMap(match, rootId);
      if (rootModel.deletedPost != true && rootModel.timeStamp <= nowMs) {
        items.add(rootModel);
      }
    } catch (_) {}
    final children = match['children'];
    if (children is List) {
      for (final entry in children) {
        if (entry is! Map) continue;
        final childData =
            Map<String, dynamic>.from(entry.cast<dynamic, dynamic>());
        final childId = (childData['docId'] ?? '').toString().trim();
        if (childId.isEmpty) continue;
        try {
          final model = PostsModel.fromMap(childData, childId);
          if (model.deletedPost == true || model.timeStamp > nowMs) {
            continue;
          }
          items.add(model);
        } catch (_) {}
      }
    }
    return items;
  }

  Future<List<PostsModel>> _loadFloodManifestSeries(String anyFloodId) async {
    final storedItems = await _loadStoredFloodManifestSeries(anyFloodId);
    if (storedItems.isNotEmpty) {
      debugPrint(
        '[FloodManifestStore] status=series_hit scope=store root=$anyFloodId count=${storedItems.length}',
      );
      unawaited(_ensureFloodManifestStoreFresh());
      return storedItems;
    }
    await _ensureFloodManifestStoreFresh(force: true);
    return _loadStoredFloodManifestSeries(anyFloodId);
  }
}
