import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Services/job_saved_store.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Models/job_model.dart';

class SavedJobsController extends GetxController {
  final JobRepository _jobRepository = JobRepository.ensure();
  RxList<JobModel> list = <JobModel>[].obs;
  RxBool isLoading = false.obs;
  static const int _whereInChunkSize = 10;

  List<List<T>> _chunkList<T>(List<T> input, int size) {
    if (input.isEmpty) return <List<T>>[];
    final chunks = <List<T>>[];
    for (int i = 0; i < input.length; i += size) {
      final end = (i + size > input.length) ? input.length : i + size;
      chunks.add(input.sublist(i, end));
    }
    return chunks;
  }

  Future<void> getStartData() async {
    isLoading.value = true;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final savedRecords = await JobSavedStore.getSavedJobs(uid);
      final savedIds = savedRecords.map((e) => e.jobId).toList();

      if (savedIds.isEmpty) {
        list.clear();
        isLoading.value = false;
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);

      final jobsById = <String, JobModel>{};
      final staleSavedIds = <String>[];
      final idsToMarkEnded = <String>[];

      for (final chunk in _chunkList(savedIds, _whereInChunkSize)) {
        final fetched = await _jobRepository.fetchByIds(chunk);
        final foundIds = fetched.map((job) => job.docID).toSet();
        for (final missingId in chunk.where((id) => !foundIds.contains(id))) {
          staleSavedIds.add(missingId);
        }

        for (final job in fetched) {
          if (job.timeStamp < thirtyDaysAgo && !job.ended) {
            idsToMarkEnded.add(job.docID);
            continue;
          }
          if (!job.ended) {
            jobsById[job.docID] = job;
          }
        }
      }

      // DB yan etkilerini batch ile uygula (tek tek write yerine).
      if (staleSavedIds.isNotEmpty) {
        for (final chunk in _chunkList(staleSavedIds, 450)) {
          await JobSavedStore.removeSavedJobs(uid, chunk);
        }
      }
      if (idsToMarkEnded.isNotEmpty) {
        for (final chunk in _chunkList(idsToMarkEnded, 450)) {
          final batch = FirebaseFirestore.instance.batch();
          for (final docId in chunk) {
            final ref = FirebaseFirestore.instance
                .collection(JobCollection.name)
                .doc(docId);
            batch.update(ref, {"ended": true});
          }
          await batch.commit();
        }
      }

      final jobs = savedIds
          .where(jobsById.containsKey)
          .map((id) => jobsById[id]!)
          .toList();

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
      print("Kaydedilen ilanlar hatası: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
