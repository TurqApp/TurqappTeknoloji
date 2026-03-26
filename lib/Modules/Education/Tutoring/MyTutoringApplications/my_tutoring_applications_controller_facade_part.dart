part of 'my_tutoring_applications_controller.dart';

extension MyTutoringApplicationsControllerFacadePart
    on MyTutoringApplicationsController {
  Future<void> loadApplications({
    bool silent = false,
    bool forceRefresh = false,
  }) =>
      _loadApplicationsImpl(
        silent: silent,
        forceRefresh: forceRefresh,
      );

  Future<void> cancelApplication(String tutoringDocID) =>
      _cancelApplicationImpl(tutoringDocID);
}
