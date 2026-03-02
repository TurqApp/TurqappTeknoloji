import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';

import '../../../Models/job_model.dart';

class MyJobAdsController extends GetxController {
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

      final snapshot = await FirebaseFirestore.instance
          .collection(JobCollection.name)
          .where("userID", isEqualTo: uid)
          .where("ended", isEqualTo: false)
          .get();

      List<JobModel> validJobs = [];

      for (var doc in snapshot.docs) {
        final job = JobModel.fromMap(doc.data(), doc.id);

        if (job.timeStamp < thirtyDaysAgo) {
          await FirebaseFirestore.instance
              .collection(JobCollection.name)
              .doc(doc.id)
              .update({"ended": true});
        } else {
          validJobs.add(job);
        }
      }

      active.value = validJobs;
      getDeactive();
    } catch (e) {
      print("getActive() hatası: $e");
    }
  }

  Future<void> getDeactive() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snapshot = await FirebaseFirestore.instance
          .collection(JobCollection.name)
          .where("userID", isEqualTo: uid)
          .where("ended", isEqualTo: true)
          .get();

      deactive.value = snapshot.docs
          .map((doc) => JobModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("getDeactive() hatası: $e");
    }
  }
}
