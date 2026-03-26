part of 'agenda_shuffle_cache_service.dart';

class AgendaShuffleCacheService extends GetxService
    with _AgendaShuffleCacheServiceBasePart {
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
