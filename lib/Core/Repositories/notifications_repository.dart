import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';

part 'notifications_repository_helpers_part.dart';
part 'notifications_repository_runtime_part.dart';

class NotificationsRepository extends GetxService {
  static NotificationsRepository? maybeFind() {
    final isRegistered = Get.isRegistered<NotificationsRepository>();
    if (!isRegistered) return null;
    return Get.find<NotificationsRepository>();
  }

  static NotificationsRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(NotificationsRepository(), permanent: true);
  }

  final FirebaseFirestore _firestore = AppFirestore.instance;
}
