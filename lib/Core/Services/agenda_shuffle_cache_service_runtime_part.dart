part of 'agenda_shuffle_cache_service.dart';

AgendaShuffleCacheService? maybeFindAgendaShuffleCacheService() =>
    _maybeFindAgendaShuffleCacheService();

AgendaShuffleCacheService ensureAgendaShuffleCacheService() =>
    _ensureAgendaShuffleCacheService();

extension AgendaShuffleCacheServiceRuntimePart on AgendaShuffleCacheService {
  List<PostsModel> takeCurrentVisible() => _takeCurrentAgendaVisiblePosts(this);
}

AgendaShuffleCacheService? _maybeFindAgendaShuffleCacheService() {
  final isRegistered = Get.isRegistered<AgendaShuffleCacheService>();
  if (!isRegistered) return null;
  return Get.find<AgendaShuffleCacheService>();
}

AgendaShuffleCacheService _ensureAgendaShuffleCacheService() {
  final existing = _maybeFindAgendaShuffleCacheService();
  if (existing != null) return existing;
  return Get.put(AgendaShuffleCacheService(), permanent: true);
}

void _clearAgendaShuffleCache(AgendaShuffleCacheService service) {
  service._posts.clear();
  service._index = 0;
  service._cachedAt = null;
}

void _removeAgendaShufflePosts(
  AgendaShuffleCacheService service,
  Iterable<String> docIds,
) {
  final ids = docIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
  if (ids.isEmpty) return;
  service._posts.removeWhere((post) => ids.contains(post.docID));
  if (service._index > service._posts.length) {
    service._index = service._posts.length;
  }
  if (service._posts.isEmpty) {
    service._cachedAt = null;
    service._index = 0;
  }
}

void _replaceAgendaShufflePosts(
  AgendaShuffleCacheService service,
  List<PostsModel> posts,
) {
  service._posts
    ..clear()
    ..addAll(posts);
  service._index = 0;
  service._cachedAt = DateTime.now();
}

void _reshuffleAgendaPosts(AgendaShuffleCacheService service) {
  service._posts.shuffle(Random());
  service._index = 0;
}

List<PostsModel> _takeNextAgendaShufflePosts(
  AgendaShuffleCacheService service,
  int limit,
) {
  if (!service.hasBufferedItems) return const <PostsModel>[];
  final remainingCount = service._posts.length - service._index;
  final takeCount = remainingCount > limit ? limit : remainingCount;
  final nextBatch = service._posts.sublist(
    service._index,
    service._index + takeCount,
  );
  service._index += takeCount;
  return nextBatch;
}

List<PostsModel> _takeCurrentAgendaVisiblePosts(
  AgendaShuffleCacheService service,
) {
  return service._posts.take(service._index).toList(growable: false);
}

void _mergeAgendaShuffleBackground(
  AgendaShuffleCacheService service,
  List<PostsModel> visibleItems,
) {
  final currentVisible = service.takeCurrentVisible();
  service._posts
    ..clear()
    ..addAll(currentVisible)
    ..addAll(
      visibleItems.where(
        (item) => !currentVisible.any((shown) => shown.docID == item.docID),
      ),
    );
}
