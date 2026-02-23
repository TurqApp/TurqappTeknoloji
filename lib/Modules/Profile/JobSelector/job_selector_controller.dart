import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/jobs.dart';

class JobSelectorController extends GetxController {
  var job = "".obs;
  var filteredJobs = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    filteredJobs.assignAll(jobs);
    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((doc) {
      job.value = doc.get("meslekKategori");
    });
  }

  void filterJobs(String query) {
    if (query.isEmpty) {
      filteredJobs.assignAll(jobs);
    } else {
      filteredJobs.assignAll(
        jobs.where((job) => job.toLowerCase().contains(query.toLowerCase())),
      );
    }
  }

  Future<void> setData() async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({"meslekKategori": job.value});

    Get.back();
  }
}
