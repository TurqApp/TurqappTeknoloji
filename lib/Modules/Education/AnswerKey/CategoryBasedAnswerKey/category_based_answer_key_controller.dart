import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';

part 'category_based_answer_key_controller_runtime_part.dart';

class CategoryBasedAnswerKeyController extends GetxController {
  static CategoryBasedAnswerKeyController ensure(
    String sinavTuru, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CategoryBasedAnswerKeyController(sinavTuru),
      tag: tag,
      permanent: permanent,
    );
  }

  static CategoryBasedAnswerKeyController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<CategoryBasedAnswerKeyController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CategoryBasedAnswerKeyController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final String sinavTuru;
  final list = <BookletModel>[].obs;
  final filteredList = <BookletModel>[].obs;
  final search = TextEditingController();
  final isLoading = true.obs;
  final BookletRepository _bookletRepository = BookletRepository.ensure();

  CategoryBasedAnswerKeyController(this.sinavTuru);

  @override
  void onInit() {
    super.onInit();
    _handleCategoryAnswerKeyInit();
  }

  @override
  void onClose() {
    _handleCategoryAnswerKeyClose();
    super.onClose();
  }
}
