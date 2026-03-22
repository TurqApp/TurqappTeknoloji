part of 'job_details_controller.dart';

extension JobDetailsControllerDataPart on JobDetailsController {
  Future<void> refreshJob() async {
    try {
      final fresh = await _jobRepository.fetchById(
        model.value.docID,
        preferCache: true,
        forceRefresh: true,
      );
      if (fresh != null) {
        model.value = fresh;
      }
    } catch (_) {}
  }

  Future<void> incrementViewCount() async {
    try {
      final uid = _currentUserId;
      if (uid.isEmpty) return;
      if (model.value.userID == uid) return;
      await _jobRepository.incrementViewCount(model.value.docID);
    } catch (_) {}
  }

  Future<void> getUserData(String userID) async {
    try {
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary == null) {
        avatarUrl.value = kDefaultAvatarUrl;
        return;
      }
      fullname.value = summary.displayName;
      nickname.value = summary.nickname.isNotEmpty
          ? summary.nickname
          : summary.preferredName;
      avatarUrl.value =
          summary.avatarUrl.isNotEmpty ? summary.avatarUrl : kDefaultAvatarUrl;
    } catch (_) {
      avatarUrl.value = kDefaultAvatarUrl;
    }
  }

  Future<void> cvCheck() async {
    try {
      final uid = _currentUserId;
      if (uid.isEmpty) {
        cvVar.value = false;
        return;
      }
      final cv = await _cvRepository.getCv(uid, preferCache: true);
      cvVar.value = cv != null;
    } catch (_) {}
  }

  Future<void> checkSaved(String docId) async {
    try {
      final uid = _currentUserId;
      if (uid.isEmpty) {
        saved.value = false;
        return;
      }
      saved.value = await JobSavedStore.isSaved(uid, docId);
    } catch (_) {
      saved.value = false;
    }
  }

  Future<void> getSimilar(String meslek) async {
    try {
      final current = model.value;
      final query = [
        current.meslek.trim(),
        current.brand.trim(),
        current.ilanBasligi.trim(),
      ].firstWhere((value) => value.isNotEmpty, orElse: () => meslek.trim());
      if (query.isEmpty) {
        list.clear();
        return;
      }

      final result = await _jobHomeSnapshotRepository.search(
        query: query,
        userId: _currentUserId,
        limit: 20,
        forceSync: true,
      );

      final jobs = (result.data ?? const <JobModel>[])
          .where((job) => _isSimilarJob(current, job))
          .take(8)
          .toList(growable: false);
      list.assignAll(jobs);
    } catch (_) {
      list.clear();
    }
  }

  Future<void> bootstrapSimilar() async {
    try {
      final current = model.value;
      final query = [
        current.meslek.trim(),
        current.brand.trim(),
        current.ilanBasligi.trim(),
      ].firstWhere(
        (value) => value.isNotEmpty,
        orElse: () => current.meslek.trim(),
      );
      if (query.isEmpty) return;
      final cached = await _jobHomeSnapshotRepository.search(
        query: query,
        userId: _currentUserId,
        limit: 20,
      );
      final cachedJobs = cached.data ?? const <JobModel>[];
      if (cachedJobs.isNotEmpty) {
        final jobs = cachedJobs
            .where((job) => _isSimilarJob(current, job))
            .take(8)
            .toList(growable: false);
        if (jobs.isNotEmpty) {
          list.assignAll(jobs);
        }
      }
    } catch (_) {}
    await getSimilar(model.value.meslek);
  }

  bool _isSimilarJob(JobModel current, JobModel other) {
    if (other.docID.isEmpty || other.docID == current.docID || other.ended) {
      return false;
    }

    final currentMeslek = normalizeSearchText(current.meslek);
    final otherMeslek = normalizeSearchText(other.meslek);
    if (currentMeslek.isNotEmpty && currentMeslek == otherMeslek) {
      return true;
    }

    final currentBrand = normalizeSearchText(current.brand);
    final otherBrand = normalizeSearchText(other.brand);
    if (currentBrand.isNotEmpty && currentBrand == otherBrand) {
      return true;
    }

    final currentTypes = current.calismaTuru.map(normalizeSearchText).toSet();
    final otherTypes = other.calismaTuru.map(normalizeSearchText).toSet();
    return currentTypes.intersection(otherTypes).isNotEmpty;
  }

  Future<void> fetchReviews(String docID) async {
    try {
      final items = await _jobRepository.fetchReviews(
        docID,
        preferCache: true,
      );
      reviews.assignAll(items);
      await _fetchReviewUsers(reviews.map((e) => e.userID));
    } catch (_) {
      reviews.clear();
    }
  }

  Future<void> bootstrapReviews() async {
    final docId = model.value.docID;
    final cached = await _jobRepository.fetchReviews(
      docId,
      preferCache: true,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      reviews.assignAll(cached);
      unawaited(_fetchReviewUsers(reviews.map((e) => e.userID)));
    }
    await fetchReviews(docId);
  }

  Future<void> _fetchReviewUsers(Iterable<String> userIDs) async {
    final uniqueIds = userIDs.where((e) => e.trim().isNotEmpty).toSet();
    final toFetch =
        uniqueIds.where((userID) => !reviewUsers.containsKey(userID));
    if (toFetch.isEmpty) return;
    final summaries = await _userRepository.getUsers(toFetch.toList());
    for (final entry in summaries.entries) {
      reviewUsers[entry.key] = entry.value.toMap();
    }
  }

  Future<void> checkBasvuru(String docID) async {
    try {
      final uid = _currentUserId;
      if (uid.isEmpty) {
        basvuruldu.value = false;
        return;
      }
      basvuruldu.value = await _jobRepository.hasApplication(docID, uid);
    } catch (_) {
      basvuruldu.value = false;
    }
  }
}
