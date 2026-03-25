part of 'swr_controller.dart';

class _SWRControllerRuntimePart<T> {
  final SWRController<T> controller;

  const _SWRControllerRuntimePart(this.controller);

  void handleOnInit() {
    unawaited(_initSWR());
  }

  Future<void> _initSWR() async {
    try {
      final cached = await controller.loadFromCache();
      if (cached.isNotEmpty && controller.items.isEmpty) {
        controller.items.assignAll(cached);
      }
    } catch (e) {
      debugPrint('[SWR] cache load error: $e');
    }

    await revalidate();
  }

  Future<void> revalidate({bool force = false}) async {
    if (controller.isRevalidating.value) return;

    if (!force && controller._lastRevalidated != null) {
      final age = DateTime.now().difference(controller._lastRevalidated!);
      if (age < controller.revalidateTTL) return;
    }

    controller.isRevalidating.value = true;
    try {
      final fresh = await controller.fetchFromNetwork();
      if (fresh.isNotEmpty) {
        controller.mergeItems(fresh);
        controller._lastRevalidated = DateTime.now();
      }
      controller.hasMore.value = fresh.isNotEmpty;
    } catch (e) {
      debugPrint('[SWR] revalidate error: $e');
    } finally {
      controller.isRevalidating.value = false;
    }
  }

  Future<void> refresh() async {
    if (controller.isLoading.value) return;
    controller.isLoading.value = true;
    try {
      controller.items.clear();
      controller.hasMore.value = true;
      controller._lastRevalidated = null;
      await _initSWR();
    } finally {
      controller.isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (controller.isLoading.value ||
        !controller.hasMore.value ||
        controller.isRevalidating.value) {
      return;
    }
    controller.isLoading.value = true;
    try {
      final nextPage = await controller.fetchFromNetwork(
          cursor: controller.paginationCursor);
      if (nextPage.isEmpty) {
        controller.hasMore.value = false;
        return;
      }
      controller.items.addAll(nextPage);
    } catch (e) {
      debugPrint('[SWR] loadMore error: $e');
    } finally {
      controller.isLoading.value = false;
    }
  }
}
