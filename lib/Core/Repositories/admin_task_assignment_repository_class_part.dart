part of 'admin_task_assignment_repository.dart';

class AdminTaskAssignmentRepository extends GetxService {
  static AdminTaskAssignmentRepository? maybeFind() {
    final isRegistered = Get.isRegistered<AdminTaskAssignmentRepository>();
    if (!isRegistered) return null;
    return Get.find<AdminTaskAssignmentRepository>();
  }

  static AdminTaskAssignmentRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AdminTaskAssignmentRepository(), permanent: true);
  }
}
