import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'admin_approval_repository_facade_part.dart';

class AdminApprovalRepository extends GetxService {
  static const String _adminConfigDocId = 'admin';

  static AdminApprovalRepository? maybeFind() {
    final isRegistered = Get.isRegistered<AdminApprovalRepository>();
    if (!isRegistered) return null;
    return Get.find<AdminApprovalRepository>();
  }

  static AdminApprovalRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AdminApprovalRepository(), permanent: true);
  }
}
