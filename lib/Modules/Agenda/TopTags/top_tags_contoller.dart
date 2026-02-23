import 'package:cloud_firestore/cloud_firestore.dart';
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
      : _repo = repository ?? TopTagsRepository();

  final navbar = Get.put(NavBarController());
  ScrollController scrollController = ScrollController();
  double _lastOffset = 0;
  RxList<HashtagModel> tags = <HashtagModel>[].obs;

  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  final RxInt visibleIndex = (-1).obs;

  final Map<int, GlobalKey> _agendaKeys = {};
  RxList<PostsModel> agendaList = <PostsModel>[].obs;

  bool isLoadingMore = false;
  bool hasMore = true;
  DocumentSnapshot? lastDoc;

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

  Future<void> fetchAgendaBigData({bool initial = false}) async {
    if (isLoadingMore || (!initial && !hasMore)) return;

    isLoadingMore = true;
    final query = FirebaseFirestore.instance
        .collection("Posts")
        .where("arsiv", isEqualTo: false)
        .where("img", isNotEqualTo: [])
        .where("flood", isEqualTo: false)
        .orderBy("timeStamp", descending: true)
        .limit(15);

    final pagedQuery =
        lastDoc != null ? query.startAfterDocument(lastDoc!) : query;

    try {
      final snap = await pagedQuery.get();
      if (initial) agendaList.clear();

      if (snap.docs.isNotEmpty) {
        lastDoc = snap.docs.last;
        for (var doc in snap.docs) {
          final model = PostsModel.fromFirestore(doc);
          if (model.deletedPost != true) {
            agendaList.add(model);
          }
        }
      } else {
        hasMore = false;
      }
    } catch (e) {
      print("Firestore fetch error: $e");
    }

    isLoadingMore = false;
  }

  Future<void> getTags() async {
    tags.clear();
    try {
      final list = await _repo.fetchTrendingTags(resultLimit: 15);
      tags.assignAll(list);
    } catch (_) {}
  }

  GlobalKey getAgendaKey(int index) {
    return _agendaKeys.putIfAbsent(
        index, () => GlobalObjectKey('agenda_$index'));
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
    final screenHeight = MediaQuery.of(context).size.height;
    final topThreshold = screenHeight * 0.33;
    final bottomThreshold = screenHeight * 0.66;

    for (int i = 0; i < agendaList.length; i++) {
      final key = getAgendaKey(i);
      final ctx = key.currentContext;
      if (ctx == null) continue;

      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;

      final position = box.localToGlobal(Offset.zero).dy;
      final height = box.size.height;
      final center = position + height / 2;

      if (center > topThreshold && center < bottomThreshold) {
        centeredIndex.value = i;
        break;
      }
    }
  }

  void disposeAgendaContentController(String docID) {
    if (Get.isRegistered<AgendaContentController>(tag: docID)) {
      Get.delete<AgendaContentController>(tag: docID, force: true);
      print("Disposed AgendaContentController for $docID");
    }
  }
}
