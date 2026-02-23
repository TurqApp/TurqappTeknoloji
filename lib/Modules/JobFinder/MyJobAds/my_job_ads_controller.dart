import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
      final now = DateTime.now().millisecondsSinceEpoch;
      final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);

      final snapshot = await FirebaseFirestore.instance
          .collection("IsBul")
          .where("userID", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where("ended", isEqualTo: false)
          .get();

      List<JobModel> validJobs = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final job = JobModel.fromMap(data, doc.id);

        if (job.timeStamp < thirtyDaysAgo) {
          // 30 günden eski ise ended = true yap
          await FirebaseFirestore.instance
              .collection("IsBul")
              .doc(doc.id)
              .update({"ended": true});
          print("🔕 Süresi dolan ilan kapatıldı: ${job.brand}");
        } else {
          validJobs.add(job); // aktif ilan listesine ekle
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
      final snapshot = await FirebaseFirestore.instance.collection("IsBul")
          .where("userID", isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .where("ended", isEqualTo: true)
          .get();

      List<JobModel> jobs = snapshot.docs.map((doc) {
        final data = doc.data();
        return JobModel.fromMap(data, doc.id);
      }).toList();

      deactive.value = jobs;
    } catch (e) {
      print("getList() hatası: $e");
    }
  }

}