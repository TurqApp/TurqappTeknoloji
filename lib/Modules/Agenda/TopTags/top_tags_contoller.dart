import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/hashtag_model.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import '../../../Models/posts_model.dart';
import '../AgendaContent/agenda_content_controller.dart';
import 'top_tags_repository.dart';

part 'top_tags_contoller_feed_part.dart';
part 'top_tags_contoller_scroll_part.dart';
part 'top_tags_contoller_lifecycle_part.dart';

class TopTagsController extends GetxController {
  static TopTagsController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(TopTagsController());
  }

  static TopTagsController? maybeFind() {
    final isRegistered = Get.isRegistered<TopTagsController>();
    if (!isRegistered) return null;
    return Get.find<TopTagsController>();
  }

  final TopTagsRepository _repo;
  TopTagsController({TopTagsRepository? repository})
      : _repo = repository ?? TopTagsRepository.ensure();

  final navbar = NavBarController.ensure();
  ScrollController scrollController = ScrollController();
  double _lastOffset = 0;
  RxList<HashtagModel> tags = <HashtagModel>[].obs;

  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  final RxInt visibleIndex = (-1).obs;
  String? _pendingCenteredDocId;

  final Map<String, GlobalKey> _agendaKeys = {};
  RxList<PostsModel> agendaList = <PostsModel>[].obs;

  bool isLoadingMore = false;
  bool hasMore = true;

  @override
  void onInit() {
    super.onInit();
    _TopTagsControllerLifecyclePart(this).handleOnInit();
  }

  @override
  void onClose() {
    _TopTagsControllerLifecyclePart(this).handleOnClose();
    super.onClose();
  }

  void resetFeedState() {
    hasMore = true;
    agendaList.clear();
    centeredIndex.value = -1;
    currentVisibleIndex.value = -1;
  }

  String agendaInstanceTag(String docId) => 'top_tag_$docId';

  GlobalKey getAgendaKey({required String docId}) {
    return _agendaKeys.putIfAbsent(
      docId,
      () => GlobalObjectKey(agendaInstanceTag(docId)),
    );
  }
}
