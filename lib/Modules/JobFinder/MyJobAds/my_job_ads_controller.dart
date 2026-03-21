import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../../Models/job_model.dart';

class MyJobAdsController extends GetxController {
  static MyJobAdsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyJobAdsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyJobAdsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MyJobAdsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyJobAdsController>(tag: tag);
  }

  final JobRepository _jobRepository = JobRepository.ensure();
  final pageController = PageController();
  final isLoadingActive = true.obs;
  final isLoadingDeactive = true.obs;
  RxList<JobModel> active = <JobModel>[].obs;
  RxList<JobModel> deactive = <JobModel>[].obs;
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  bool _sameJobEntries(List<JobModel> current, List<JobModel> next) {
    final currentKeys = current
        .map(
          (job) => [
            job.docID,
            job.logo,
            job.brand,
            job.meslek,
            job.ilanBasligi,
            job.city,
            job.town,
            job.timeStamp,
            job.viewCount,
            job.applicationCount,
            job.ended,
            job.calismaTuru.join('|'),
          ].join('::'),
        )
        .toList(growable: false);
    final nextKeys = next
        .map(
          (job) => [
            job.docID,
            job.logo,
            job.brand,
            job.meslek,
            job.ilanBasligi,
            job.city,
            job.town,
            job.timeStamp,
            job.viewCount,
            job.applicationCount,
            job.ended,
            job.calismaTuru.join('|'),
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrap());
  }

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _bootstrap() async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) {
      isLoadingActive.value = false;
      isLoadingDeactive.value = false;
      return;
    }

    final cachedActive = await _jobRepository.fetchByOwnerAndEnded(
      uid,
      ended: false,
      cacheOnly: true,
    );
    if (cachedActive.isNotEmpty) {
      final nextActive = _filterAndNormalizeExpired(cachedActive);
      if (!_sameJobEntries(active, nextActive)) {
        active.assignAll(nextActive);
      }
      isLoadingActive.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'jobs:my_ads:active:$uid',
        minInterval: _silentRefreshInterval,
      )) {
        unawaited(getActive(silent: true, forceRefresh: true));
      }
    } else {
      await getActive();
    }

    final cachedEnded = await _jobRepository.fetchByOwnerAndEnded(
      uid,
      ended: true,
      cacheOnly: true,
    );
    if (cachedEnded.isNotEmpty) {
      if (!_sameJobEntries(deactive, cachedEnded)) {
        deactive.assignAll(cachedEnded);
      }
      isLoadingDeactive.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'jobs:my_ads:ended:$uid',
        minInterval: _silentRefreshInterval,
      )) {
        unawaited(getDeactive(silent: true, forceRefresh: true));
      }
      return;
    }

    if (deactive.isEmpty) {
      await getDeactive();
    }
  }

  Future<void> getActive({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent) {
      isLoadingActive.value = true;
    }
    try {
      final uid = CurrentUserService.instance.userId;
      if (uid.isEmpty) return;
      final jobs = await _jobRepository.fetchByOwnerAndEnded(
        uid,
        ended: false,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      final nextActive = _filterAndNormalizeExpired(jobs);
      if (!_sameJobEntries(active, nextActive)) {
        active.assignAll(nextActive);
      }
      SilentRefreshGate.markRefreshed('jobs:my_ads:active:$uid');
    } catch (_) {
    } finally {
      isLoadingActive.value = false;
    }
  }

  Future<void> getDeactive({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent) {
      isLoadingDeactive.value = true;
    }
    try {
      final uid = CurrentUserService.instance.userId;
      if (uid.isEmpty) return;
      final nextDeactive = await _jobRepository.fetchByOwnerAndEnded(
        uid,
        ended: true,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      if (!_sameJobEntries(deactive, nextDeactive)) {
        deactive.value = nextDeactive;
      }
      SilentRefreshGate.markRefreshed('jobs:my_ads:ended:$uid');
    } catch (_) {
    } finally {
      isLoadingDeactive.value = false;
    }
  }

  List<JobModel> _filterAndNormalizeExpired(List<JobModel> jobs) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);
    final validJobs = <JobModel>[];

    for (final job in jobs) {
      if (job.timeStamp < thirtyDaysAgo) {
        unawaited(FirebaseFirestore.instance
            .collection(JobCollection.name)
            .doc(job.docID)
            .update({"ended": true}));
      } else {
        validJobs.add(job);
      }
    }

    return validJobs;
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
