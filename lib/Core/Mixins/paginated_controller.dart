import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Cursor-based pagination mixin for GetxControllers.
///
/// Usage:
/// ```dart
/// class MyController extends GetxController with PaginatedController<MyModel> {
///   @override
///   int get pageSize => 30;
///
///   @override
///   Query<Map<String, dynamic>> buildQuery() {
///     return FirebaseFirestore.instance
///         .collection('myCollection')
///         .orderBy('timeStamp', descending: true);
///   }
///
///   @override
///   MyModel fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
///     return MyModel.fromJson(doc.data(), doc.id);
///   }
/// }
/// ```
mixin PaginatedController<T> on GetxController {
  final RxList<T> paginatedItems = <T>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;

  DocumentSnapshot? _lastDocument;

  int get pageSize => 30;

  /// Override to build the base query (without limit/startAfter).
  Query<Map<String, dynamic>> buildQuery();

  /// Override to parse a Firestore document into your model.
  T fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> doc);

  /// Optional: filter items after fetching (e.g. remove ended items).
  bool filterItem(T item) => true;

  Future<void> loadInitial() async {
    isLoading.value = true;
    hasMore.value = true;
    _lastDocument = null;
    try {
      final snap = await buildQuery().limit(pageSize).get();
      final items = snap.docs.map(fromSnapshot).where(filterItem).toList();
      paginatedItems.assignAll(items);
      if (snap.docs.isNotEmpty) _lastDocument = snap.docs.last;
      if (snap.docs.length < pageSize) hasMore.value = false;
    } catch (_) {
      paginatedItems.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_lastDocument == null || isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final snap = await buildQuery()
          .startAfterDocument(_lastDocument!)
          .limit(pageSize)
          .get();

      final items = snap.docs.map(fromSnapshot).where(filterItem).toList();
      paginatedItems.addAll(items);
      if (snap.docs.isNotEmpty) _lastDocument = snap.docs.last;
      if (snap.docs.length < pageSize) hasMore.value = false;
    } catch (_) {
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Attach this to a ScrollController to trigger loadMore automatically.
  void onScroll(ScrollController scrollController) {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore.value &&
        hasMore.value) {
      loadMore();
    }
  }
}
