import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'support_message_repository_facade_part.dart';

class SupportMessageRepository extends GetxService {
  static SupportMessageRepository? maybeFind() {
    final isRegistered = Get.isRegistered<SupportMessageRepository>();
    if (!isRegistered) return null;
    return Get.find<SupportMessageRepository>();
  }

  static SupportMessageRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SupportMessageRepository(), permanent: true);
  }
}
