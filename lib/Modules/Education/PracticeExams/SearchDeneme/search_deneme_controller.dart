import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_snapshot_repository.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'search_deneme_controller_runtime_part.dart';

class SearchDenemeController extends GetxController {
  static SearchDenemeController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SearchDenemeController(), permanent: permanent);
  }

  static SearchDenemeController? maybeFind() {
    final isRegistered = Get.isRegistered<SearchDenemeController>();
    if (!isRegistered) return null;
    return Get.find<SearchDenemeController>();
  }

  final PracticeExamSnapshotRepository _practiceExamSnapshotRepository =
      PracticeExamSnapshotRepository.ensure();
  final filteredList = <SinavModel>[].obs;
  final isLoading = false.obs;
  final TextEditingController searchController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  int _searchToken = 0;

  @override
  void onInit() {
    super.onInit();
    _handleSearchDenemeOnInit();
  }

  Future<void> getData() => _performSearchDenemeDataLoad();

  Future<void> filterSearchResults(String query) =>
      _performFilterSearchResults(query);

  @override
  void onClose() {
    _handleSearchDenemeOnClose();
    super.onClose();
  }
}
