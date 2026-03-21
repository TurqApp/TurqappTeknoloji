import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/job_repository.dart';
import 'package:turqappv2/Core/Services/job_saved_store.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class SavedJobsController extends GetxController {
  static SavedJobsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SavedJobsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static SavedJobsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SavedJobsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SavedJobsController>(tag: tag);
  }

  final JobRepository _jobRepository = JobRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  RxList<JobModel> list = <JobModel>[].obs;
  RxBool isLoading = false.obs;
  static const int _whereInChunkSize = 10;
  Position? _lastResolvedPosition;

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
            job.kacKm.toStringAsFixed(2),
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
            job.kacKm.toStringAsFixed(2),
            job.calismaTuru.join('|'),
          ].join('::'),
        )
        .toList(growable: false);
    return listEquals(currentKeys, nextKeys);
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapSavedJobs());
  }

  List<List<T>> _chunkList<T>(List<T> input, int size) {
    if (input.isEmpty) return <List<T>>[];
    final chunks = <List<T>>[];
    for (int i = 0; i < input.length; i += size) {
      final end = (i + size > input.length) ? input.length : i + size;
      chunks.add(input.sublist(i, end));
    }
    return chunks;
  }

  Future<void> _bootstrapSavedJobs() async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) {
      list.clear();
      isLoading.value = false;
      return;
    }

    try {
      final cachedSavedRecords = await JobSavedStore.getSavedJobs(
        uid,
        cacheOnly: true,
      );
      if (cachedSavedRecords.isNotEmpty) {
        await _loadSavedJobs(
          uid,
          cachedSavedRecords,
          silent: true,
          cacheOnlyJobs: true,
        );
        if (list.isNotEmpty) {
          if (SilentRefreshGate.shouldRefresh(
            'jobs:saved:$uid',
            minInterval: _silentRefreshInterval,
          )) {
            unawaited(getStartData(silent: true, forceRefresh: true));
          }
          return;
        }
      }
    } catch (_) {}

    await getStartData();
  }

  Future<void> getStartData({
    bool silent = false,
    bool forceRefresh = false,
    bool allowLocationPrompt = false,
  }) async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) {
      list.clear();
      isLoading.value = false;
      return;
    }

    final savedRecords = await JobSavedStore.getSavedJobs(
      uid,
      forceRefresh: forceRefresh,
    );
    await _loadSavedJobs(
      uid,
      savedRecords,
      silent: silent,
      allowLocationPrompt: allowLocationPrompt,
    );
    SilentRefreshGate.markRefreshed('jobs:saved:$uid');
  }

  Future<void> _loadSavedJobs(
    String uid,
    List<SavedJobRecord> savedRecords, {
    bool silent = false,
    bool cacheOnlyJobs = false,
    bool allowLocationPrompt = false,
  }) async {
    final shouldShowLoader = !silent && list.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }

    try {
      final savedIds = savedRecords.map((e) => e.jobId).toList();

      if (savedIds.isEmpty) {
        if (list.isNotEmpty) {
          list.clear();
        }
        return;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final thirtyDaysAgo = now - (30 * 24 * 60 * 60 * 1000);

      final jobsById = <String, JobModel>{};
      final staleSavedIds = <String>[];
      final idsToMarkEnded = <String>[];

      for (final chunk in _chunkList(savedIds, _whereInChunkSize)) {
        final fetched = await _jobRepository.fetchByIds(
          chunk,
          cacheOnly: cacheOnlyJobs,
        );
        final foundIds = fetched.map((job) => job.docID).toSet();
        for (final missingId in chunk.where((id) => !foundIds.contains(id))) {
          if (cacheOnlyJobs) continue;
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
      if (!cacheOnlyJobs && staleSavedIds.isNotEmpty) {
        for (final chunk in _chunkList(staleSavedIds, 450)) {
          await JobSavedStore.removeSavedJobs(uid, chunk);
        }
      }
      if (!cacheOnlyJobs && idsToMarkEnded.isNotEmpty) {
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

      final position = await _resolveUserPosition(
        allowPermissionPrompt: allowLocationPrompt,
      );
      if (position == null) {
        jobs.shuffle();
        if (!_sameJobEntries(list, jobs)) {
          list.value = jobs;
        }
        return;
      }
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
      if (!_sameJobEntries(list, updatedJobs)) {
        list.value = updatedJobs;
      }
    } catch (_) {
    } finally {
      if (shouldShowLoader || list.isEmpty) {
        isLoading.value = false;
      }
    }
  }

  Future<Position?> _resolveUserPosition({
    required bool allowPermissionPrompt,
  }) async {
    try {
      final lastResolved = _lastResolvedPosition;
      if (lastResolved != null) {
        return lastResolved;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        if (!allowPermissionPrompt) {
          return await Geolocator.getLastKnownPosition();
        }
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return await Geolocator.getLastKnownPosition();
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _lastResolvedPosition = lastKnown;
        return lastKnown;
      }

      final current = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      _lastResolvedPosition = current;
      return current;
    } catch (_) {
      return null;
    }
  }
}
