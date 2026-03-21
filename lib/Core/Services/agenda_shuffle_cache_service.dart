import 'dart:math';

import 'package:get/get.dart';
import 'package:turqappv2/Models/posts_model.dart';

class AgendaShuffleCacheService extends GetxService {
  static const int _cacheValidMinutes = 5;
  static const int _initialFetchSize = 60;
  static const int _backgroundFetchSize = 300;

  final List<PostsModel> _posts = <PostsModel>[];
  int _index = 0;
  DateTime? _cachedAt;

  static AgendaShuffleCacheService? maybeFind() {
    final isRegistered = Get.isRegistered<AgendaShuffleCacheService>();
    if (!isRegistered) return null;
    return Get.find<AgendaShuffleCacheService>();
  }

  static AgendaShuffleCacheService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AgendaShuffleCacheService(), permanent: true);
  }

  int get initialFetchSize => _initialFetchSize;
  int get backgroundFetchSize => _backgroundFetchSize;
  int get currentIndex => _index;
  bool get hasBufferedItems => _posts.isNotEmpty && _index < _posts.length;
  bool get hasMore => _posts.length > _index;

  bool get isFresh {
    if (_cachedAt == null) return false;
    final diff = DateTime.now().difference(_cachedAt!).inMinutes;
    return diff < _cacheValidMinutes;
  }

  void clear() {
    _posts.clear();
    _index = 0;
    _cachedAt = null;
  }

  void removePosts(Iterable<String> docIds) {
    final ids = docIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
    if (ids.isEmpty) return;
    _posts.removeWhere((post) => ids.contains(post.docID));
    if (_index > _posts.length) {
      _index = _posts.length;
    }
    if (_posts.isEmpty) {
      _cachedAt = null;
      _index = 0;
    }
  }

  void replace(List<PostsModel> posts) {
    _posts
      ..clear()
      ..addAll(posts);
    _index = 0;
    _cachedAt = DateTime.now();
  }

  void reshuffle() {
    _posts.shuffle(Random());
    _index = 0;
  }

  List<PostsModel> takeNext(int limit) {
    if (!hasBufferedItems) return const <PostsModel>[];
    final remainingCount = _posts.length - _index;
    final takeCount = remainingCount > limit ? limit : remainingCount;
    final nextBatch = _posts.sublist(_index, _index + takeCount);
    _index += takeCount;
    return nextBatch;
  }

  List<PostsModel> takeCurrentVisible() {
    return _posts.take(_index).toList(growable: false);
  }

  void mergeBackground(List<PostsModel> visibleItems) {
    final currentVisible = takeCurrentVisible();
    _posts
      ..clear()
      ..addAll(currentVisible)
      ..addAll(
        visibleItems.where(
          (item) => !currentVisible.any((shown) => shown.docID == item.docID),
        ),
      );
  }
}
