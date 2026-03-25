import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/tutoring_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:flutter/material.dart';

part 'my_tutorings_controller_sync_part.dart';

class MyTutoringsController extends GetxController {
  static MyTutoringsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyTutoringsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyTutoringsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MyTutoringsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyTutoringsController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final TutoringRepository _tutoringRepository = TutoringRepository.ensure();
  final RxList<TutoringModel> myTutorings = <TutoringModel>[].obs;
  final RxMap<String, Map<String, dynamic>> users =
      <String, Map<String, dynamic>>{}.obs;
  final RxString errorMessage = ''.obs;
  final RxList<TutoringModel> activeTutorings = <TutoringModel>[].obs;
  final RxList<TutoringModel> expiredTutorings = <TutoringModel>[].obs;
  final PageController pageController = PageController();
  final RxInt selection = 0.obs;
  final RxBool isLoading = true.obs;

  bool _sameTutoringEntries(
    List<TutoringModel> current,
    List<TutoringModel> next,
  ) {
    final currentKeys = current
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.brans,
            item.sehir,
            item.ilce,
            item.fiyat,
            item.timeStamp,
            item.viewCount ?? 0,
            item.applicationCount ?? 0,
            item.ended,
            item.endedAt,
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (item) => [
            item.docID,
            item.baslik,
            item.brans,
            item.sehir,
            item.ilce,
            item.fiyat,
            item.timeStamp,
            item.viewCount ?? 0,
            item.applicationCount ?? 0,
            item.ended,
            item.endedAt,
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  @override
  void onInit() {
    super.onInit();
    final uid = getCurrentUserId();
    if (uid != null) {
      unawaited(_bootstrapData(uid));
    } else {
      errorMessage.value = 'tutoring.user_id_missing'.tr;
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void updateTutoringsStatus() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysInMillis = 30 * 24 * 60 * 60 * 1000;
    activeTutorings.clear();
    expiredTutorings.clear();

    for (var tutoring in myTutorings) {
      if (tutoring.ended == true ||
          now - tutoring.timeStamp > thirtyDaysInMillis) {
        expiredTutorings.add(tutoring);
      } else {
        activeTutorings.add(tutoring);
      }
    }
  }

  Future<void> fetchUsers(
    Set<String> userIds, {
    bool cacheOnly = false,
  }) async {
    final toFetch = userIds.where((id) => !users.containsKey(id)).toList();
    if (toFetch.isEmpty) return;

    try {
      final rawUsers = await _userSummaryResolver.resolveMany(
        toFetch,
        preferCache: true,
        cacheOnly: cacheOnly,
      );
      for (final entry in rawUsers.entries) {
        users[entry.key] = entry.value.toMap();
      }
    } catch (e) {
      errorMessage.value = 'tutoring.user_load_failed'.trParams({
        'error': e.toString(),
      });
    }
  }

  String? getCurrentUserId() {
    final uid = CurrentUserService.instance.effectiveUserId;
    return uid.isNotEmpty ? uid : null;
  }

  void goToPage(int index) {
    selection.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
