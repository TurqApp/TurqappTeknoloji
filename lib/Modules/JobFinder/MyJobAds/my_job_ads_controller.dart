import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';

import '../../../Models/job_model.dart';

class MyJobAdsController extends GetxController {
  final JobRepository _jobRepository = JobRepository.ensure();
  final pageController = PageController();
  final isLoadingActive = true.obs;
  final isLoadingDeactive = true.obs;
  RxList<JobModel> active = <JobModel>[].obs;
  RxList<JobModel> deactive = <JobModel>[].obs;
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  static final Map<String, DateTime> _lastRefreshAtByUid = <String, DateTime>{};

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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
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
      active.assignAll(_filterAndNormalizeExpired(cachedActive));
      isLoadingActive.value = false;
      if (_shouldRefresh(uid)) {
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
      deactive.assignAll(cachedEnded);
      isLoadingDeactive.value = false;
      if (_shouldRefresh(uid)) {
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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final jobs = await _jobRepository.fetchByOwnerAndEnded(
        uid,
        ended: false,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      active.assignAll(_filterAndNormalizeExpired(jobs));
      _markRefreshed(uid);
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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      deactive.value = await _jobRepository.fetchByOwnerAndEnded(
        uid,
        ended: true,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      _markRefreshed(uid);
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

  bool _shouldRefresh(String uid) {
    final last = _lastRefreshAtByUid[uid];
    if (last == null) return true;
    return DateTime.now().difference(last) >= _silentRefreshInterval;
  }

  void _markRefreshed(String uid) {
    _lastRefreshAtByUid[uid] = DateTime.now();
  }
}
