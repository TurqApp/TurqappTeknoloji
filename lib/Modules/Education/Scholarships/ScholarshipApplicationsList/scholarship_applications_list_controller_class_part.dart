part of 'scholarship_applications_list_controller.dart';

class ScholarshipApplicationsListController extends GetxController {
  final _ScholarshipApplicationsListControllerState _state;

  ScholarshipApplicationsListController({
    required String docID,
    required List<String> basvuranlar,
  }) : _state = _ScholarshipApplicationsListControllerState(
          docID: docID,
          basvuranlar: basvuranlar,
        );
}
