import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/answer_key_sub_model.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletAnswer/booklet_answer.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'booklet_preview_controller_fields_part.dart';
part 'booklet_preview_controller_facade_part.dart';
part 'booklet_preview_controller_runtime_part.dart';

class BookletPreviewController extends GetxController {
  static BookletPreviewController ensure(
    BookletModel model, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      BookletPreviewController(model),
      tag: tag,
      permanent: permanent,
    );
  }

  static BookletPreviewController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<BookletPreviewController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<BookletPreviewController>(tag: tag);
  }

  final _BookletPreviewControllerState _state;

  BookletPreviewController(BookletModel model)
      : _state = _BookletPreviewControllerState(model: model);

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }
}
