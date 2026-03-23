import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Chat/chat_constants.dart';

part 'conversation_repository_query_part.dart';
part 'conversation_repository_message_part.dart';
part 'conversation_repository_state_part.dart';
part 'conversation_repository_helpers_part.dart';

class ConversationRepository extends GetxService {
  static ConversationRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ConversationRepository>();
    if (!isRegistered) return null;
    return Get.find<ConversationRepository>();
  }

  static ConversationRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ConversationRepository(), permanent: true);
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
}
