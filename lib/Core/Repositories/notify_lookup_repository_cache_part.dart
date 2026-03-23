part of 'notify_lookup_repository.dart';

extension NotifyLookupRepositoryCachePart on NotifyLookupRepository {
  void _pruneStaleLookups() {
    final now = DateTime.now();
    bool isStale(DateTime t) =>
        now.difference(t) > NotifyLookupRepository._staleRetention;
    _postLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _chatLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _jobLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _tutoringLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _marketLookupCache.removeWhere((_, v) => isStale(v.cachedAt));
    _trimOldestIfNeeded();
  }

  void _trimOldestIfNeeded() {
    void trimMap<T>(
      Map<String, T> map,
      DateTime Function(T value) cachedAt,
    ) {
      if (map.length <= NotifyLookupRepository._maxLookupEntries) return;
      final entries = map.entries.toList()
        ..sort((a, b) => cachedAt(a.value).compareTo(cachedAt(b.value)));
      final removeCount = map.length - NotifyLookupRepository._maxLookupEntries;
      for (var i = 0; i < removeCount; i++) {
        map.remove(entries[i].key);
      }
    }

    trimMap<NotifyPostLookup>(_postLookupCache, (v) => v.cachedAt);
    trimMap<NotifyChatLookup>(_chatLookupCache, (v) => v.cachedAt);
    trimMap<NotifyJobLookup>(_jobLookupCache, (v) => v.cachedAt);
    trimMap<NotifyTutoringLookup>(_tutoringLookupCache, (v) => v.cachedAt);
    trimMap<NotifyMarketLookup>(_marketLookupCache, (v) => v.cachedAt);
  }
}
