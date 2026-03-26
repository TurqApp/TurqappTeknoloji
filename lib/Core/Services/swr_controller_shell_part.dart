part of 'swr_controller.dart';

/// Stale-While-Revalidate (SWR) GetX Controller Base
///
/// Kullanım adımları:
/// 1. [loadFromCache] — önce disk/LRU cache'ten hızlı göster (ağ yok)
/// 2. [fetchFromNetwork] — arka planda Firestore'dan tazele
/// 3. [mergeItems] — taze veriyi mevcut listeyle birleştir
///
/// ```dart
/// class UserPostsController extends SWRController<PostsModel> {
///   @override
///   Future<List<PostsModel>> loadFromCache() async {
///     return await _pool.loadPosts(IndexPoolKind.feed);
///   }
///
///   @override
///   Future<List<PostsModel>> fetchFromNetwork({PostsModel? startAfter}) async {
///     // Firestore get()
///   }
///
///   @override
///   void mergeItems(List<PostsModel> fresh) {
///     final ids = fresh.map((p) => p.docID).toSet();
///     items.removeWhere((p) => ids.contains(p.docID));
///     items.insertAll(0, fresh);
///   }
/// }
/// ```
abstract class SWRController<T> extends GetxController {
  final _state = _SWRControllerState<T>();

  Duration get revalidateTTL => const Duration(minutes: 5);

  Future<List<T>> loadFromCache();

  Future<List<T>> fetchFromNetwork({T? cursor});

  void mergeItems(List<T> fresh) {
    items.addAll(fresh);
  }

  T? get paginationCursor => items.isEmpty ? null : items.last;

  @override
  void onInit() {
    super.onInit();
    _SWRControllerRuntimePart<T>(this).handleOnInit();
  }

  @override
  Future<void> refresh() => _SWRControllerRuntimePart<T>(this).refresh();
}
