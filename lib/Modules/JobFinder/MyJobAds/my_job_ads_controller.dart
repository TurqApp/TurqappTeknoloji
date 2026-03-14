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
  RxList<JobModel> active = <JobModel>[].obs;
  RxList<JobModel> deactive = <JobModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    getActive();
  }

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> getActive() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final now = DateTime.now().millisecondsSinceEpoch;
      final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);

      final jobs = await _jobRepository.fetchByOwnerAndEnded(
        uid,
        ended: false,
      );

      List<JobModel> validJobs = [];

      for (final job in jobs) {
        if (job.timeStamp < thirtyDaysAgo) {
          await FirebaseFirestore.instance
              .collection(JobCollection.name)
              .doc(job.docID)
              .update({"ended": true});
        } else {
          validJobs.add(job);
        }
      }

      active.value = validJobs;
      getDeactive();
    } catch (_) {
    }
  }

  Future<void> getDeactive() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      deactive.value = await _jobRepository.fetchByOwnerAndEnded(
        uid,
        ended: true,
      );
    } catch (_) {
    }
  }
}
