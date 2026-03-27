part of 'my_applications_controller.dart';

const Duration _myApplicationsSilentRefreshInterval = Duration(minutes: 5);

class MyApplicationsController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapApplicationsImpl());
  }
}

MyApplicationsController ensureMyApplicationsController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindMyApplicationsController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    MyApplicationsController(),
    tag: tag,
    permanent: permanent,
  );
}

MyApplicationsController? maybeFindMyApplicationsController({String? tag}) {
  final isRegistered = Get.isRegistered<MyApplicationsController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<MyApplicationsController>(tag: tag);
}

extension MyApplicationsControllerRuntimePart on MyApplicationsController {
  Future<void> _bootstrapApplicationsImpl() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      isLoading.value = false;
      return;
    }
    final cached = await _subcollectionRepository.getEntries(
      uid,
      subcollection: 'myApplications',
      orderByField: 'timeStamp',
      descending: true,
      preferCache: true,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      applications.value = cached
          .map((doc) => JobApplicationModel.fromMap(doc.data, doc.id))
          .toList(growable: false);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'jobs:my_applications:$uid',
        minInterval: _myApplicationsSilentRefreshInterval,
      )) {
        unawaited(loadApplications(silent: true, forceRefresh: true));
      }
      return;
    }
    await loadApplications();
  }

  Future<void> loadApplications({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _loadApplicationsImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<void> _loadApplicationsImpl({
    required bool silent,
    required bool forceRefresh,
  }) async {
    if (!silent) {
      isLoading.value = true;
    }
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;
      final items = await _subcollectionRepository.getEntries(
        uid,
        subcollection: 'myApplications',
        orderByField: 'timeStamp',
        descending: true,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );

      applications.value = items
          .map((doc) => JobApplicationModel.fromMap(doc.data, doc.id))
          .toList(growable: false);
      SilentRefreshGate.markRefreshed('jobs:my_applications:$uid');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> cancelApplication(String jobDocID) =>
      _cancelApplicationImpl(jobDocID);

  Future<void> _cancelApplicationImpl(String jobDocID) async {
    try {
      final uid = CurrentUserService.instance.effectiveUserId;
      if (uid.isEmpty) return;

      await _jobRepository.cancelApplication(
        jobDocId: jobDocID,
        userId: uid,
      );

      applications.removeWhere((a) => a.jobDocID == jobDocID);
      await _subcollectionRepository.setEntries(
        uid,
        subcollection: 'myApplications',
        items: applications
            .map(
              (e) => UserSubcollectionEntry(
                id: e.jobDocID,
                data: e.toMap(),
              ),
            )
            .toList(growable: false),
      );
    } catch (_) {}
  }
}
