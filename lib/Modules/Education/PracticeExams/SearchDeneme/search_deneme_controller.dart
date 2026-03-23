import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_snapshot_repository.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'search_deneme_controller_search_part.dart';
part 'search_deneme_controller_lifecycle_part.dart';

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

  bool _sameExamEntries(
    List<SinavModel> current,
    List<SinavModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.sinavAdi,
            item.sinavTuru,
            item.timeStamp,
            item.participantCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.sinavAdi,
            item.sinavTuru,
            item.timeStamp,
            item.participantCount,
            item.cover,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  @override
  void onInit() {
    super.onInit();
    _scheduleFocusRequestImpl();
  }

  Future<void> getData() => _getDataImpl();

  Future<void> filterSearchResults(String query) =>
      _filterSearchResultsImpl(query);

  @override
  void onClose() {
    _disposeFocusResourcesImpl();
    super.onClose();
  }
}
