import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class SupportMessageRepository extends GetxService {
  static SupportMessageRepository ensure() {
    if (Get.isRegistered<SupportMessageRepository>()) {
      return Get.find<SupportMessageRepository>();
    }
    return Get.put(SupportMessageRepository(), permanent: true);
  }

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('supportMessages');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOwnMessages(String userId) {
    if (userId.trim().isEmpty) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _ref.where('userId', isEqualTo: userId.trim()).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchInbox() {
    return _ref.orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> createMessage({
    required String topic,
    required String message,
  }) async {
    final currentService = CurrentUserService.instance;
    final current = currentService.currentUser;
    final uid = currentService.userId.trim().isNotEmpty
        ? currentService.userId.trim()
        : (FirebaseAuth.instance.currentUser?.uid ?? '').trim();
    if (uid.trim().isEmpty) {
      throw Exception('not_authenticated');
    }
    final normalizedTopic = topic.trim();
    final text = message.trim();
    if (normalizedTopic.isEmpty) {
      throw Exception('empty_topic');
    }
    if (text.isEmpty) {
      throw Exception('empty_message');
    }

    await _ref.add(<String, dynamic>{
      'userId': uid,
      'nickname': (current?.nickname ?? '').trim(),
      'displayName': (current?.fullName ?? '').trim(),
      'avatarUrl': (current?.avatarUrl ?? '').trim(),
      'rozet': (current?.rozet ?? '').trim(),
      'email': currentService.email.trim(),
      'topic': normalizedTopic,
      'message': text,
      'status': 'open',
      'adminNote': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
      'resolvedBy': '',
      'resolvedByNickname': '',
    });
  }

  Future<void> setStatus({
    required String docId,
    required String status,
    String adminNote = '',
  }) async {
    final currentService = CurrentUserService.instance;
    final current = currentService.currentUser;
    await _ref.doc(docId).set(<String, dynamic>{
      'status': status.trim(),
      'adminNote': adminNote.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'resolvedAt':
          status.trim() == 'open' ? null : FieldValue.serverTimestamp(),
      'resolvedBy': status.trim() == 'open' ? '' : currentService.userId,
      'resolvedByNickname':
          status.trim() == 'open' ? '' : (current?.nickname.trim() ?? ''),
    }, SetOptions(merge: true));
  }
}
