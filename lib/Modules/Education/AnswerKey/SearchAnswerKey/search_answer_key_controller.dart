import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/answer_key_snapshot_repository.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/BookletPreview/booklet_preview.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'search_answer_key_controller_runtime_part.dart';

class SearchAnswerKeyController extends GetxController {
  static SearchAnswerKeyController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SearchAnswerKeyController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static SearchAnswerKeyController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SearchAnswerKeyController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SearchAnswerKeyController>(tag: tag);
  }

  final searchController = TextEditingController();
  final filteredList = <BookletModel>[].obs;
  final isLoading = false.obs;
  final AnswerKeySnapshotRepository _answerKeySnapshotRepository =
      AnswerKeySnapshotRepository.ensure();
  int _searchToken = 0;

  @override
  void onInit() {
    super.onInit();
    _handleSearchAnswerKeyOnInit();
  }

  @override
  void onClose() {
    _handleSearchAnswerKeyOnClose();
    super.onClose();
  }

  void navigateToPreview(BookletModel model) {
    Get.to(() => BookletPreview(model: model));
  }
}
