import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/hashtag_model.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/AgendaContent/agenda_content_controller.dart';
import 'package:turqappv2/Modules/Agenda/TopTags/top_tags_repository.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';

part 'top_tags_contoller_feed_part.dart';
part 'top_tags_contoller_fields_part.dart';
part 'top_tags_contoller_scroll_part.dart';

class TopTagsController extends _TopTagsControllerBase {
  TopTagsController({super.repository});
}

abstract class _TopTagsControllerBase extends GetxController {
  _TopTagsControllerBase({TopTagsRepository? repository})
      : _repo = repository ?? ensureTopTagsRepository();

  final TopTagsRepository _repo;
  final _state = _TopTagsControllerState();

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_onScroll);
    getTags();
    fetchAgendaBigData(initial: true);
  }

  @override
  void onClose() {
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.onClose();
  }
}

TopTagsController ensureTopTagsController() => _ensureTopTagsController();

TopTagsController? maybeFindTopTagsController() =>
    _maybeFindTopTagsController();

TopTagsController _ensureTopTagsController() {
  final existing = _maybeFindTopTagsController();
  if (existing != null) return existing;
  return Get.put(TopTagsController());
}

TopTagsController? _maybeFindTopTagsController() {
  final isRegistered = Get.isRegistered<TopTagsController>();
  if (!isRegistered) return null;
  return Get.find<TopTagsController>();
}

extension TopTagsControllerFacadePart on _TopTagsControllerBase {
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
