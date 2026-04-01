part of 'saved_job_controller_library.dart';

extension SavedJobsControllerRuntimeX on SavedJobsController {
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

  Future<void> _handleOnInit() async {
    await _bootstrapSavedJobsImpl();
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
      return List<JobModel>.from(jobs);
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
