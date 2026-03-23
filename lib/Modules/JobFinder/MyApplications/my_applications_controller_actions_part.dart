part of 'my_applications_controller.dart';

extension MyApplicationsControllerActionsPart on MyApplicationsController {
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
