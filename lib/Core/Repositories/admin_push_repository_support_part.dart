part of 'admin_push_repository.dart';

const String _adminPushDefaultImageUrl =
    'https://firebasestorage.googleapis.com/v0/b/turqappteknoloji.firebasestorage.app/o/logoblack.png?alt=media&token=23085c34-c823-48d9-a650-2342ec801d23';

final UserRepository _adminPushUserRepository = UserRepository.ensure();

AdminPushRepository? _maybeFindAdminPushRepository() {
  final isRegistered = Get.isRegistered<AdminPushRepository>();
  if (!isRegistered) return null;
  return Get.find<AdminPushRepository>();
}

AdminPushRepository _ensureAdminPushRepository() {
  final existing = _maybeFindAdminPushRepository();
  if (existing != null) return existing;
  return Get.put(AdminPushRepository(), permanent: true);
}

CollectionReference<Map<String, dynamic>> _adminPushReportsRef() {
  return AppFirestore.instance
      .collection('adminConfig')
      .doc('admin')
      .collection('pushReports');
}
