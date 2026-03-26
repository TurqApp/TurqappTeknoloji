import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/hashtag_model.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import '../../../Models/posts_model.dart';
import '../AgendaContent/agenda_content_controller.dart';
import 'top_tags_repository.dart';

part 'top_tags_contoller_feed_part.dart';
part 'top_tags_contoller_facade_part.dart';
part 'top_tags_contoller_fields_part.dart';
part 'top_tags_contoller_scroll_part.dart';
part 'top_tags_contoller_lifecycle_part.dart';

class TopTagsController extends GetxController {
  static TopTagsController ensure() => ensureTopTagsController();

  static TopTagsController? maybeFind() => maybeFindTopTagsController();

  final TopTagsRepository _repo;
  TopTagsController({TopTagsRepository? repository})
      : _repo = repository ?? TopTagsRepository.ensure();
  final _state = _TopTagsControllerState();

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
}
