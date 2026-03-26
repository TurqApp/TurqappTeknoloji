part of 'scholarship_applications_list_controller.dart';

class _ScholarshipApplicationsListControllerState {
  _ScholarshipApplicationsListControllerState({
    required this.docID,
    required this.basvuranlar,
  });

  final String docID;
  final List<String> basvuranlar;
  final RxBool isRefreshing = false.obs;
}

extension ScholarshipApplicationsListControllerFieldsPart
    on ScholarshipApplicationsListController {
  String get docID => _state.docID;
  List<String> get basvuranlar => _state.basvuranlar;
  RxBool get isRefreshing => _state.isRefreshing;
}
