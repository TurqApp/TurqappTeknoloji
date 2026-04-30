part of 'saved_job_controller_library.dart';

extension SavedJobsControllerDataPart on SavedJobsController {
  List<List<T>> _chunkListImpl<T>(List<T> input, int size) {
    if (input.isEmpty) return <List<T>>[];
    final chunks = <List<T>>[];
    for (int i = 0; i < input.length; i += size) {
      final end = (i + size > input.length) ? input.length : i + size;
      chunks.add(input.sublist(i, end));
    }
    return chunks;
  }

  Future<void> _bootstrapSavedJobsImpl() async {
    final uid = CurrentUserService.instance.effectiveUserId;
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
        await _loadSavedJobsImpl(
          uid,
          cachedSavedRecords,
          silent: true,
          cacheOnlyJobs: true,
        );
        if (list.isNotEmpty) {
          if (SilentRefreshGate.shouldRefresh(
            'jobs:saved:$uid',
            minInterval: _savedJobsSilentRefreshInterval,
          )) {
            unawaited(getStartData(silent: true, forceRefresh: true));
          }
          return;
        }
      }
    } catch (_) {}

    await getStartData();
  }

  Future<void> _getStartDataImpl({
    required bool silent,
    required bool forceRefresh,
    required bool allowLocationPrompt,
  }) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      list.clear();
      isLoading.value = false;
      return;
    }

    final savedRecords = await JobSavedStore.getSavedJobs(
      uid,
      forceRefresh: forceRefresh,
    );
    await _loadSavedJobsImpl(
      uid,
      savedRecords,
      silent: silent,
      allowLocationPrompt: allowLocationPrompt,
    );
    SilentRefreshGate.markRefreshed('jobs:saved:$uid');
  }

  Future<void> _loadSavedJobsImpl(
    String uid,
    List<SavedJobRecord> savedRecords, {
    required bool silent,
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

      for (final chunk in _chunkListImpl(
        savedIds,
        _savedJobsWhereInChunkSize,
      )) {
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

      if (!cacheOnlyJobs && staleSavedIds.isNotEmpty) {
        for (final chunk in _chunkListImpl(staleSavedIds, 450)) {
          await JobSavedStore.removeSavedJobs(uid, chunk);
        }
      }
      if (!cacheOnlyJobs && idsToMarkEnded.isNotEmpty) {
        for (final chunk in _chunkListImpl(idsToMarkEnded, 450)) {
          await _jobRepository.markEndedBatch(chunk);
        }
      }

      final jobs = savedIds
          .where(jobsById.containsKey)
          .map((id) => jobsById[id]!)
          .toList();

      final sortedJobs = await _sortJobsByDistanceImpl(
        jobs,
        allowLocationPrompt: allowLocationPrompt,
      );
      if (!_sameJobEntries(list, sortedJobs)) {
        list.value = sortedJobs;
      }
    } catch (_) {
    } finally {
      if (shouldShowLoader || list.isEmpty) {
        isLoading.value = false;
      }
    }
  }
}
