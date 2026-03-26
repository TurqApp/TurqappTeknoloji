import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Modules/Chat/chat_unread_policy.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../Services/network_awareness_service.dart';

part 'unread_messages_controller_fields_part.dart';
part 'unread_messages_controller_support_part.dart';
part 'unread_messages_controller_sync_part.dart';

class UnreadMessagesController extends GetxController {
  static UnreadMessagesController ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(UnreadMessagesController());
  }

  static UnreadMessagesController? maybeFind() {
    final isRegistered = Get.isRegistered<UnreadMessagesController>();
    if (!isRegistered) return null;
    return Get.find<UnreadMessagesController>();
  }

  final _state = _UnreadMessagesControllerState();

  @override
  void onInit() {
    super.onInit();
    if (_currentUid.isNotEmpty) {
      startListeners();
    }
  }

  @override
  void onClose() {
    _cancelAllSubscriptions();
    super.onClose();
  }
}
