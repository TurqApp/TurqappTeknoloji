part of 'job_content_controller.dart';

Future<void> _warmSavedIdsForCurrentUserImpl() async {
  final uid = CurrentUserService.instance.effectiveUserId;
  if (uid.isEmpty) return;
  final cached = JobContentController._savedIdsByUser[uid];
  if (cached != null) return;
  final records = await JobSavedStore.getSavedJobs(
    uid,
    preferCache: true,
  );
  JobContentController._savedIdsByUser[uid] =
      records.map((record) => record.jobId).toSet();
}

extension JobContentControllerSavedPart on JobContentController {
  Future<Set<String>> _loadSavedIds(String uid) {
    final cached = JobContentController._savedIdsByUser[uid];
    if (cached != null) return Future<Set<String>>.value(cached);
    return JobContentController._savedIdsLoaders.putIfAbsent(uid, () async {
      try {
        final records = await JobSavedStore.getSavedJobs(
          uid,
          preferCache: true,
        );
        final ids = records.map((record) => record.jobId).toSet();
        JobContentController._savedIdsByUser[uid] = ids;
        return ids;
      } finally {
        JobContentController._savedIdsLoaders.remove(uid);
      }
    });
  }

  Future<void> _primeSavedStateImpl(String docId) async {
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty || _initializedSavedDocId == normalizedDocId) {
      return;
    }
    _initializedSavedDocId = normalizedDocId;
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      final savedIds = await _loadSavedIds(uid);
      saved.value = savedIds.contains(normalizedDocId);
    } catch (_) {
      saved.value = false;
    }
  }

  Future<void> _toggleSaveImpl(String docId) async {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.saveJob)) {
      return;
    }
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;

    try {
      final savedIds = await _loadSavedIds(uid);
      final isAlreadySaved = savedIds.contains(docId);
      if (isAlreadySaved) {
        await JobSavedStore.unsave(uid, docId);
        savedIds.remove(docId);
        saved.value = false;
      } else {
        await JobSavedStore.save(uid, docId);
        savedIds.add(docId);
        saved.value = true;
      }
    } catch (_) {}
  }
}
