import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

part 'swr_controller_runtime_part.dart';

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
  // ─── Public state ──────────────────────────────────────────────
  final RxList<T> items = <T>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isRevalidating = false.obs;
  final RxBool hasMore = true.obs;

  // ─── Configuration ─────────────────────────────────────────────
  /// Cache TTL: bu süre içinde bir önceki tazelemedeyse ağa gitme
  Duration get revalidateTTL => const Duration(minutes: 5);

  DateTime? _lastRevalidated;

  // ─── Abstract interface ────────────────────────────────────────

  /// Disk veya LRU cache'ten hızlı yükle. Ağ çağrısı yapma.
  /// Boş liste dönmek geçerlidir (ilk açılış).
  Future<List<T>> loadFromCache();

  /// Firestore / API'den taze veri çek.
  /// [cursor]: pagination için son eleman (null = ilk sayfa)
  Future<List<T>> fetchFromNetwork({T? cursor});

  /// [fresh] verilerini mevcut [items] listesiyle birleştir.
  /// Varsayılan: başa ekle + duplicate kaldır. Override edebilirsin.
  void mergeItems(List<T> fresh) {
    items.addAll(fresh);
  }

  /// [items] büyüdükçe daha fazla yüklemek için kullanılır.
  /// null dönmek "son sayfa" anlamına gelir.
  T? get paginationCursor => items.isEmpty ? null : items.last;

  // ─── Lifecycle ─────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _SWRControllerRuntimePart<T>(this).handleOnInit();
  }

  /// Ağdan taze veri çek ve items'ı güncelle.
  /// [force] = TTL'yi görmezden gel ve her zaman ağa git.
  Future<void> revalidate({bool force = false}) =>
      _SWRControllerRuntimePart<T>(this).revalidate(force: force);

  /// Sayfayı sıfırla ve baştan yükle.
  @override
  Future<void> refresh() => _SWRControllerRuntimePart<T>(this).refresh();

  /// Sonraki sayfayı yükle (infinite scroll).
  Future<void> loadMore() => _SWRControllerRuntimePart<T>(this).loadMore();
}
