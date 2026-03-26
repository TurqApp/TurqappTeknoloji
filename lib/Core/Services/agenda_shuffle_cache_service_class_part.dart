part of 'agenda_shuffle_cache_service.dart';

class AgendaShuffleCacheService extends GetxService
    with _AgendaShuffleCacheServiceBasePart {
  static const int _cacheValidMinutes = 5;
  static const int _initialFetchSize = 60;
  static const int _backgroundFetchSize = 300;

  void clear() => _clearAgendaShuffleCache(this);

  void removePosts(Iterable<String> docIds) =>
      _removeAgendaShufflePosts(this, docIds);

  void replace(List<PostsModel> posts) =>
      _replaceAgendaShufflePosts(this, posts);

  void reshuffle() => _reshuffleAgendaPosts(this);

  List<PostsModel> takeNext(int limit) =>
      _takeNextAgendaShufflePosts(this, limit);

  void mergeBackground(List<PostsModel> visibleItems) =>
      _mergeAgendaShuffleBackground(this, visibleItems);
}
