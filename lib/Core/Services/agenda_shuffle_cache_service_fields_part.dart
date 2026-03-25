part of 'agenda_shuffle_cache_service.dart';

class _AgendaShuffleCacheServiceState {
  final posts = <PostsModel>[];
  int index = 0;
  DateTime? cachedAt;
}

extension AgendaShuffleCacheServiceFieldsPart on AgendaShuffleCacheService {
  List<PostsModel> get _posts => _state.posts;
  int get _index => _state.index;
  set _index(int value) => _state.index = value;
  DateTime? get _cachedAt => _state.cachedAt;
  set _cachedAt(DateTime? value) => _state.cachedAt = value;

  int get initialFetchSize => AgendaShuffleCacheService._initialFetchSize;
  int get backgroundFetchSize => AgendaShuffleCacheService._backgroundFetchSize;
  int get currentIndex => _index;
  bool get hasBufferedItems => _posts.isNotEmpty && _index < _posts.length;
  bool get hasMore => _posts.length > _index;

  bool get isFresh {
    if (_cachedAt == null) return false;
    final diff = DateTime.now().difference(_cachedAt!).inMinutes;
    return diff < AgendaShuffleCacheService._cacheValidMinutes;
  }
}
