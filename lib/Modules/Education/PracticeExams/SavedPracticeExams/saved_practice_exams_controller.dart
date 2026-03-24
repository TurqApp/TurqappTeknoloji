import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'saved_practice_exams_controller_data_part.dart';

class SavedPracticeExamsController extends GetxController {
  static SavedPracticeExamsController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SavedPracticeExamsController(), permanent: permanent);
  }

  static SavedPracticeExamsController? maybeFind() {
    final isRegistered = Get.isRegistered<SavedPracticeExamsController>();
    if (!isRegistered) return null;
    return Get.find<SavedPracticeExamsController>();
  }

  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();
  final UserSubcollectionRepository _subcollectionRepository =
      UserSubcollectionRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final RxList<String> savedExamIds = <String>[].obs;
  final RxList<SinavModel> savedExams = <SinavModel>[].obs;
  final RxBool isLoading = false.obs;

  bool _sameIds(Iterable<String> next) {
    return listEquals(
      savedExamIds.toList(growable: false),
      next.toList(growable: false),
    );
  }

  bool _sameExamEntries(List<SinavModel> current, List<SinavModel> next) {
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
    unawaited(_bootstrapDataImpl());
  }

  Future<void> loadSavedExams({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _loadSavedExamsImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<void> _toggleSavedExamImpl(String docId) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;

    if (savedExamIds.contains(docId)) {
      savedExamIds.remove(docId);
      savedExams.removeWhere((exam) => exam.docID == docId);
      await _subcollectionRepository.deleteEntry(
        uid,
        subcollection: 'saved_practice_exams',
        docId: docId,
      );
      return;
    }

    savedExamIds.add(docId);
    await _subcollectionRepository.upsertEntry(
      uid,
      subcollection: 'saved_practice_exams',
      docId: docId,
      data: {
        'timeStamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<void> toggleSavedExam(String docId) => _toggleSavedExamImpl(docId);
}
