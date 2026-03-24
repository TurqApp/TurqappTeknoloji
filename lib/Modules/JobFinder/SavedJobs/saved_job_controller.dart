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

part 'saved_job_controller_data_part.dart';

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
    unawaited(_bootstrapSavedJobsImpl());
  }

  Future<void> getStartData({
    bool silent = false,
    bool forceRefresh = false,
    bool allowLocationPrompt = false,
  }) =>
      _getStartDataImpl(
        silent: silent,
        forceRefresh: forceRefresh,
        allowLocationPrompt: allowLocationPrompt,
      );

  Future<List<JobModel>> _sortJobsByDistanceImpl(
    List<JobModel> jobs, {
    required bool allowLocationPrompt,
  }) async {
    final position = await _resolveUserPositionImpl(
      allowPermissionPrompt: allowLocationPrompt,
    );
    if (position == null) {
      final shuffled = List<JobModel>.from(jobs)..shuffle();
      return shuffled;
    }

    final userLat = position.latitude;
    final userLong = position.longitude;

    final updatedJobs = jobs.map((job) {
      final distanceInMeters = Geolocator.distanceBetween(
        userLat,
        userLong,
        job.lat,
        job.long,
      );
      final distanceInKm = distanceInMeters / 1000;

      return job.copyWith(
        kacKm: double.parse(distanceInKm.toStringAsFixed(2)),
      );
    }).toList();

    updatedJobs.sort((a, b) => a.kacKm.compareTo(b.kacKm));
    return updatedJobs;
  }

  Future<Position?> _resolveUserPositionImpl({
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
