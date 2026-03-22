import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

part 'search_tests_controller_data_part.dart';
part 'search_tests_controller_filter_part.dart';

class SearchTestsController extends GetxController {
  static SearchTestsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SearchTestsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static SearchTestsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SearchTestsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SearchTestsController>(tag: tag);
  }

  final TestRepository _testRepository = TestRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final list = <TestsModel>[].obs;
  final filteredList = <TestsModel>[].obs;
  final isLoading = true.obs;
  final searchController = TextEditingController();
  final focusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }

  @override
  void onClose() {
    _handleControllerClose();
    super.onClose();
  }
}
