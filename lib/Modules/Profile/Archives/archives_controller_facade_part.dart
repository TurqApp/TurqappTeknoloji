part of 'archives_controller.dart';

extension ArchiveControllerFacadePart on ArchiveController {
  Future<void> fetchData({bool silent = false}) async {
    await _ArchiveControllerDataPart(this).fetchArchiveData(silent: silent);
  }
}
