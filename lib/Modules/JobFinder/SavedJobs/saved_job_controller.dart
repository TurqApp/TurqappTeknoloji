import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/job_model.dart';

class SavedJobsController extends GetxController {
  RxList<JobModel> list = <JobModel>[].obs;
  RxBool isLoading = false.obs;

  Future<void> getStartData() async {
    isLoading.value = true;

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final savedSnap = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("SavedIsBul")
          .get();

      final savedIds = savedSnap.docs.map((e) => e.id).toList();

      if (savedIds.isEmpty) {
        list.clear();
        isLoading.value = false;
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);

      List<JobModel> jobs = [];

      for (String docId in savedIds) {
        final jobDoc = await FirebaseFirestore.instance
            .collection("IsBul")
            .doc(docId)
            .get();

        if (!jobDoc.exists) {
          // IsBul içinde yoksa SavedIsBul'dan sil
          await FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection("SavedIsBul")
              .doc(docId)
              .delete();

          print("🗑️ Saved'dan silindi: $docId");
          continue;
        }

        final data = jobDoc.data()!;
        final job = JobModel.fromMap(data, docId);

        if (job.timeStamp < thirtyDaysAgo && !job.ended) {
          await FirebaseFirestore.instance
              .collection("IsBul")
              .doc(docId)
              .update({"ended": true});
          print("🔕 Süresi dolan ilan kapatıldı: ${job.brand}");
          continue;
        }

        if (!job.ended) {
          jobs.add(job);
        }
      }

      // Konum bilgisi varsa mesafe hesapla
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        jobs.shuffle();
        list.value = jobs;
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          list.value = jobs;
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      double userLat = position.latitude;
      double userLong = position.longitude;

      List<JobModel> updatedJobs = jobs.map((job) {
        double distanceInMeters = Geolocator.distanceBetween(
          userLat,
          userLong,
          job.lat,
          job.long,
        );
        double distanceInKm = distanceInMeters / 1000;

        return job.copyWith(
          kacKm: double.parse(distanceInKm.toStringAsFixed(2)),
        );
      }).toList();

      updatedJobs.sort((a, b) => a.kacKm.compareTo(b.kacKm));
      list.value = updatedJobs;
    } catch (e) {
      print("Hata oluştu: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
