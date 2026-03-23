part of 'saved_job_controller.dart';

extension SavedJobsControllerLocationPart on SavedJobsController {
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
