import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

part 'deneme_turleri_listesi_controller_data_part.dart';

class DenemeTurleriListesiController extends GetxController {
  static DenemeTurleriListesiController ensure({
    required String tag,
    required String sinavTuru,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      DenemeTurleriListesiController(sinavTuru: sinavTuru),
      tag: tag,
      permanent: permanent,
    );
  }

  static DenemeTurleriListesiController? maybeFind({required String tag}) {
    final isRegistered =
        Get.isRegistered<DenemeTurleriListesiController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<DenemeTurleriListesiController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  var list = <SinavModel>[].obs;
  var isLoading = false.obs;
  var isInitialized = false.obs;

  final String sinavTuru;
  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();

  DenemeTurleriListesiController({required this.sinavTuru});

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
    unawaited(_bootstrapDataImpl());
  }

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _getDataImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );
}
