part of 'report_repository.dart';

class ReportRepository extends GetxService {
  static ReportRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ReportRepository>();
    if (!isRegistered) return null;
    return Get.find<ReportRepository>();
  }

  static ReportRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ReportRepository(), permanent: true);
  }
}
