import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/hashtag_model.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import '../../../Models/posts_model.dart';
import '../AgendaContent/agenda_content_controller.dart';
import 'top_tags_repository.dart';

class TopTagsController extends GetxController {
  final TopTagsRepository _repo;
  TopTagsController({TopTagsRepository? repository})
      : _repo = repository ?? TopTagsRepository.ensure();

  final navbar = Get.isRegistered<NavBarController>()
      ? Get.find<NavBarController>()
      : Get.put(NavBarController());
  ScrollController scrollController = ScrollController();
  double _lastOffset = 0;
  RxList<HashtagModel> tags = <HashtagModel>[].obs;

  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  final RxInt visibleIndex = (-1).obs;
  String? _pendingCenteredDocId;

  final Map<int, GlobalKey> _agendaKeys = {};
  RxList<PostsModel> agendaList = <PostsModel>[].obs;

  bool isLoadingMore = false;
  bool hasMore = true;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    getTags();
    fetchAgendaBigData(initial: true);
  }

  @override
  void onClose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.onClose();
  }

  void resetFeedState() {
    hasMore = true;
    agendaList.clear();
    centeredIndex.value = -1;
    currentVisibleIndex.value = -1;
  }

  Future<void> fetchAgendaBigData({bool initial = false}) async {
    if (isLoadingMore || (!initial && !hasMore)) return;

    isLoadingMore = true;
    if (initial) {
      final currentCentered = centeredIndex.value;
      if (currentCentered >= 0 && currentCentered < agendaList.length) {
        _pendingCenteredDocId = agendaList[currentCentered].docID;
      } else if (lastCenteredIndex != null &&
          lastCenteredIndex! >= 0 &&
          lastCenteredIndex! < agendaList.length) {
        _pendingCenteredDocId = agendaList[lastCenteredIndex!].docID;
      }
    }

    try {
      final before = agendaList.length;
      final items = await _repo.fetchImagePostsPage(
        limit: 15,
        reset: initial,
      );
      agendaList.assignAll(items);
      _restoreCenteredPost();
      if (items.length == before) {
        hasMore = false;
      }
    } catch (e) {
      print("Firestore fetch error: $e");
    }

    isLoadingMore = false;
  }

  Future<void> getTags() async {
    try {
      final list = await _repo.fetchTrendingTags(resultLimit: 15);
      tags.assignAll(list);
    } catch (_) {}
  }

  GlobalKey getAgendaKey(int index) {
    return _agendaKeys.putIfAbsent(
        index, () => GlobalObjectKey('agenda_$index'));
  }

  int _resolveRestoreIndex() {
    if (agendaList.isEmpty) return -1;
    final pendingDocId = _pendingCenteredDocId;
    if (pendingDocId != null && pendingDocId.isNotEmpty) {
      final mapped =
          agendaList.indexWhere((post) => post.docID == pendingDocId);
      if (mapped >= 0) return mapped;
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < agendaList.length) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < agendaList.length) {
      return centeredIndex.value;
    }
    return 0;
  }

  void _restoreCenteredPost() {
    final target = _resolveRestoreIndex();
    if (target < 0 || target >= agendaList.length) return;
    centeredIndex.value = target;
    currentVisibleIndex.value = target;
    lastCenteredIndex = target;
    _pendingCenteredDocId = null;
  }

  void resumeCenteredPost() {
    _restoreCenteredPost();
  }

  void _onScroll() {
    final currentOffset = scrollController.offset;

    if (currentOffset > 1000) {
      navbar.showBar.value = currentOffset < _lastOffset;
    } else {
      navbar.showBar.value = true;
    }
    _lastOffset = currentOffset;

    // Scroll sonunda veri yükle
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 300) {
      fetchAgendaBigData();
    }

    // Ortadaki öğeyi belirleme
    double itemHeight = 500;
    int newIndex = (scrollController.offset + Get.height / 2) ~/ itemHeight - 1;

    if (newIndex != currentVisibleIndex.value &&
        newIndex >= 0 &&
        newIndex < agendaList.length) {
      if (lastCenteredIndex != null && lastCenteredIndex != newIndex) {
        final prevModel = agendaList[lastCenteredIndex!];
        disposeAgendaContentController(prevModel.docID);
      }
      currentVisibleIndex.value = newIndex;
      lastCenteredIndex = newIndex;
    }
  }

  void updateVisibleIndexByPosition(
      ScrollMetrics metrics, BuildContext context) {
    if (agendaList.isEmpty) return;
    if (metrics.pixels <= 0) {
      centeredIndex.value = 0;
      currentVisibleIndex.value = 0;
      lastCenteredIndex = 0;
      return;
    }
    final estimatedItemExtent = (metrics.viewportDimension * 0.74).clamp(
      320.0,
      680.0,
    );
    final nextIndex = (((metrics.pixels + metrics.viewportDimension * 0.25) /
                estimatedItemExtent)
            .floor())
        .clamp(0, agendaList.length - 1);
    centeredIndex.value = nextIndex;
    currentVisibleIndex.value = nextIndex;
    lastCenteredIndex = nextIndex;
  }

  void disposeAgendaContentController(String docID) {
    if (Get.isRegistered<AgendaContentController>(tag: docID)) {
      Get.delete<AgendaContentController>(tag: docID, force: true);
      print("Disposed AgendaContentController");
    }
  }
}
