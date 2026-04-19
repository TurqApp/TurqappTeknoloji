part of 'typesense_post_service.dart';

extension TypesensePostServiceQueryPart on TypesensePostService {
  String _motorCandidatesCacheKey({
    required String surface,
    required List<int> ownedMinutes,
    required int limit,
    required int page,
    required int? nowMs,
    required int? cutoffMs,
  }) {
    final nowBucket = nowMs == null ? 0 : nowMs ~/ 30000;
    final cutoffBucket = cutoffMs == null ? 0 : cutoffMs ~/ 60000;
    return [
      surface,
      ownedMinutes.join(','),
      '$limit',
      '$page',
      '$nowBucket',
      '$cutoffBucket',
    ].join('|');
  }

  void _pruneMotorCandidatesCache() {
    _motorCandidatesMemory.removeWhere((_, cached) => !cached.isFresh);
  }

  Future<TypesenseMotorCandidatesResult> _performFetchMotorCandidates({
    required String surface,
    required List<int> ownedMinutes,
    required int limit,
    required int page,
    required int? nowMs,
    required int? cutoffMs,
  }) async {
    final normalizedSurface = surface.trim().toLowerCase();
    final normalizedMinutes = ownedMinutes
        .map((minute) => minute.clamp(0, 59))
        .toSet()
        .toList(growable: false)
      ..sort();
    if (normalizedSurface.isEmpty || normalizedMinutes.isEmpty) {
      return const TypesenseMotorCandidatesResult(
        surface: '',
        ownedMinutes: <int>[],
        limit: 0,
        page: 1,
        found: 0,
        outOf: 0,
        searchTimeMs: 0,
        hits: <Map<String, dynamic>>[],
      );
    }

    _pruneMotorCandidatesCache();
    final cacheKey = _motorCandidatesCacheKey(
      surface: normalizedSurface,
      ownedMinutes: normalizedMinutes,
      limit: limit,
      page: page,
      nowMs: nowMs,
      cutoffMs: cutoffMs,
    );
    final cached = _motorCandidatesMemory[cacheKey];
    if (cached != null && cached.isFresh) {
      return cached.result;
    }
    final inFlight = _motorCandidatesInFlight[cacheKey];
    if (inFlight != null) {
      return inFlight;
    }

    final future = _fetchMotorCandidatesFromTargets(
      surface: normalizedSurface,
      ownedMinutes: normalizedMinutes,
      limit: limit,
      page: page,
      nowMs: nowMs,
      cutoffMs: cutoffMs,
    ).then((result) {
      _motorCandidatesMemory[cacheKey] = _CachedMotorCandidatesResult(
        result: result,
        cachedAt: DateTime.now(),
      );
      return result;
    }).whenComplete(() {
      _motorCandidatesInFlight.remove(cacheKey);
    });
    _motorCandidatesInFlight[cacheKey] = future;
    return future;
  }

  Future<void> _performPrimeMotorCandidates({
    required String surface,
    required List<int> ownedMinutes,
    required int limit,
    required int page,
    required int? nowMs,
    required int? cutoffMs,
  }) async {
    try {
      await _performFetchMotorCandidates(
        surface: surface,
        ownedMinutes: ownedMinutes,
        limit: limit,
        page: page,
        nowMs: nowMs,
        cutoffMs: cutoffMs,
      );
    } catch (_) {}
  }

  Future<TypesenseMotorCandidatesResult> _fetchMotorCandidatesFromTargets({
    required String surface,
    required List<int> ownedMinutes,
    required int limit,
    required int page,
    required int? nowMs,
    required int? cutoffMs,
  }) async {
    Object? lastError;
    for (final target in _targets) {
      final startedAt = DateTime.now();
      try {
        debugPrint(
          '[TypesenseMotorCall] status=start target=${target.label} '
          'surface=$surface page=$page limit=$limit '
          'ownedMinutes=${ownedMinutes.join(",")}',
        );
        final response = await target.fn
            .httpsCallable('f15_getMotorCandidatesCallable')
            .call(
          <String, dynamic>{
            'surface': surface,
            'ownedMinutes': ownedMinutes,
            'limit': limit,
            'page': page,
            if (nowMs != null) 'nowMs': nowMs,
            if (cutoffMs != null) 'cutoffMs': cutoffMs,
          },
        );
        final data = Map<String, dynamic>.from(response.data as Map? ?? {});
        final hitsRaw = (data['hits'] as List<dynamic>?) ?? const <dynamic>[];
        final hits = hitsRaw
            .whereType<Map>()
            .map(
              (raw) => _cloneTypesensePostCard(
                Map<String, dynamic>.from(raw.cast<dynamic, dynamic>()),
              ),
            )
            .toList(growable: false);
        final responseMinutes =
            ((data['ownedMinutes'] as List<dynamic>?) ?? ownedMinutes)
                .map((value) => int.tryParse('$value') ?? 0)
                .where((value) => value >= 0 && value <= 59)
                .toList(growable: false);
        final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
        debugPrint(
          '[TypesenseMotorCall] status=ok target=${target.label} '
          'elapsedMs=$elapsedMs found=${data['found'] ?? 0} '
          'outOf=${data['out_of'] ?? 0} searchTimeMs=${data['search_time_ms'] ?? 0}',
        );
        return TypesenseMotorCandidatesResult(
          surface: (data['surface'] ?? surface).toString(),
          ownedMinutes: responseMinutes,
          limit: int.tryParse('${data['limit'] ?? limit}') ?? limit,
          page: int.tryParse('${data['page'] ?? page}') ?? page,
          found: int.tryParse('${data['found'] ?? 0}') ?? 0,
          outOf: int.tryParse('${data['out_of'] ?? 0}') ?? 0,
          searchTimeMs: int.tryParse('${data['search_time_ms'] ?? 0}') ?? 0,
          hits: hits,
        );
      } catch (e) {
        final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
        debugPrint(
          '[TypesenseMotorCall] status=fail target=${target.label} '
          'elapsedMs=$elapsedMs error=$e',
        );
        lastError = e;
      }
    }

    throw lastError ?? Exception('typesense_motor_candidates_failed');
  }

  Future<Map<String, Map<String, dynamic>>> _performGetPostCardsByIds(
    List<String> ids, {
    required bool preferCache,
    required bool forceRefresh,
    required bool cacheOnly,
  }) async {
    final cleaned = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return const <String, Map<String, dynamic>>{};

    final cacheKey = _cardsCacheKey(cleaned);
    if (!forceRefresh && preferCache) {
      final memoryHit = _getFromMemory(cacheKey);
      if (memoryHit != null) return _cloneTypesensePostCards(memoryHit.cards);

      final diskHit = await _getFromPrefs(cacheKey);
      if (diskHit != null) return _cloneTypesensePostCards(diskHit.cards);
    }
    if (cacheOnly) return const <String, Map<String, dynamic>>{};

    Object? lastError;
    for (final target in _targets) {
      try {
        final response =
            await target.fn.httpsCallable('f15_getPostCardsByIdsCallable').call(
          <String, dynamic>{'ids': cleaned},
        );
        final data = Map<String, dynamic>.from(response.data as Map? ?? {});
        final hits = (data['hits'] as List<dynamic>?) ?? const <dynamic>[];
        final out = <String, Map<String, dynamic>>{};
        for (final rawHit in hits) {
          final hitMap =
              rawHit is Map ? Map<String, dynamic>.from(rawHit) : null;
          if (hitMap == null) continue;
          final id = (hitMap['id'] ?? hitMap['docID'] ?? '').toString().trim();
          if (id.isEmpty) continue;
          out[id] = _cloneTypesensePostCard(hitMap);
        }
        await _store(cacheKey, out);
        return _cloneTypesensePostCards(out);
      } catch (e) {
        lastError = e;
      }
    }

    throw lastError ?? Exception('typesense_post_cards_failed');
  }

  Future<void> _performSyncPostById(String postId) async {
    final cleaned = postId.trim();
    if (cleaned.isEmpty) return;
    await invalidatePostId(cleaned);

    Object? lastError;
    for (final target in _targets) {
      try {
        debugPrint(
          '[TypesensePostService] syncPostById start postId=$cleaned target=${target.label}',
        );
        await target.fn.httpsCallable('f15_syncPostToTypesenseCallable').call(
          <String, dynamic>{'postId': cleaned},
        );
        debugPrint(
          '[TypesensePostService] syncPostById success postId=$cleaned target=${target.label}',
        );
        return;
      } catch (e) {
        debugPrint(
          '[TypesensePostService] syncPostById failed postId=$cleaned target=${target.label} error=$e',
        );
        lastError = e;
      }
    }

    debugPrint(
      '[TypesensePostService] syncPostById giving up postId=$cleaned error=$lastError',
    );
    throw lastError ?? Exception('typesense_post_sync_failed');
  }
}
