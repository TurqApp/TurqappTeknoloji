import 'dart:math';

import 'package:get/get.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'agenda_shuffle_cache_service_fields_part.dart';
part 'agenda_shuffle_cache_service_runtime_part.dart';

class AgendaShuffleCacheService extends GetxService {
  static const int _cacheValidMinutes = 5;
  static const int _initialFetchSize = 60;
  static const int _backgroundFetchSize = 300;
  final _state = _AgendaShuffleCacheServiceState();

  void clear() => _clearAgendaShuffleCache(this);

  void removePosts(Iterable<String> docIds) =>
      _removeAgendaShufflePosts(this, docIds);

  void replace(List<PostsModel> posts) =>
      _replaceAgendaShufflePosts(this, posts);

  void reshuffle() => _reshuffleAgendaPosts(this);

  List<PostsModel> takeNext(int limit) =>
      _takeNextAgendaShufflePosts(this, limit);

  List<PostsModel> takeCurrentVisible() => _takeCurrentAgendaVisiblePosts(this);

  void mergeBackground(List<PostsModel> visibleItems) =>
      _mergeAgendaShuffleBackground(this, visibleItems);
}
