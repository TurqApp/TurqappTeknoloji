import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

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
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) return;

    final savedEntries = await _subcollectionRepository.getEntries(
      uid,
      subcollection: 'saved_practice_exams',
      orderByField: 'timeStamp',
      descending: true,
      cacheOnly: true,
    );
    final cachedIds = savedEntries.map((doc) => doc.id).toList(growable: false);
    if (!_sameIds(cachedIds)) {
      savedExamIds.assignAll(cachedIds);
    }
    if (savedEntries.isNotEmpty) {
      final exams = await _practiceExamRepository.fetchByIds(
        savedEntries.map((doc) => doc.id).toList(growable: false),
        cacheOnly: true,
      );
      if (exams.isNotEmpty) {
        if (!_sameExamEntries(savedExams, exams)) {
          savedExams.assignAll(exams);
        }
        isLoading.value = false;
        if (SilentRefreshGate.shouldRefresh(
          'practice_exams:saved:$uid',
          minInterval: _silentRefreshInterval,
        )) {
          unawaited(loadSavedExams(silent: true, forceRefresh: true));
        }
        return;
      }
    }
    await loadSavedExams();
  }

  Future<void> loadSavedExams({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) return;

    if (!silent || savedExams.isEmpty) {
      isLoading.value = true;
    }
    try {
      final savedEntries = await _subcollectionRepository.getEntries(
        uid,
        subcollection: 'saved_practice_exams',
        orderByField: 'timeStamp',
        descending: true,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );

      final nextIds = savedEntries.map((doc) => doc.id).toList(growable: false);
      if (!_sameIds(nextIds)) {
        savedExamIds.assignAll(nextIds);
      }
      if (savedEntries.isEmpty) {
        if (savedExams.isNotEmpty) {
          savedExams.clear();
        }
        return;
      }

      final exams = await _practiceExamRepository.fetchByIds(
        savedEntries.map((doc) => doc.id).toList(growable: false),
        preferCache: !forceRefresh,
      );
      if (!_sameExamEntries(savedExams, exams)) {
        savedExams.assignAll(exams);
      }
      SilentRefreshGate.markRefreshed('practice_exams:saved:$uid');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleSavedExam(String docId) async {
    final uid = CurrentUserService.instance.userId;
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
}
