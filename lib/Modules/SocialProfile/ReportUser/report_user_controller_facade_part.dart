part of 'report_user_controller.dart';

extension ReportUserControllerFacadePart on ReportUserController {
  Future<void> report() => _ReportUserControllerRuntimePart(this).report();

  Future<void> block() => _ReportUserControllerRuntimePart(this).block();
}
