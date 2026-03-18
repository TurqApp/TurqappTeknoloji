import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/admin_task_catalog.dart';

class AdminTaskAssignmentRepository extends GetxService {
  static AdminTaskAssignmentRepository ensure() {
    if (Get.isRegistered<AdminTaskAssignmentRepository>()) {
      return Get.find<AdminTaskAssignmentRepository>();
    }
    return Get.put(AdminTaskAssignmentRepository(), permanent: true);
  }

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance.collection('adminTaskAssignments');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAssignments() {
    return _ref.orderBy('updatedAt', descending: true).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchAssignment(
    String userId,
  ) {
    if (userId.trim().isEmpty) {
      return const Stream<DocumentSnapshot<Map<String, dynamic>>>.empty();
    }
    return _ref.doc(userId.trim()).snapshots();
  }

  Future<Map<String, dynamic>?> fetchAssignment(String userId) async {
    if (userId.trim().isEmpty) return null;
    final doc = await _ref.doc(userId.trim()).get();
    return doc.data();
  }

  Future<void> saveAssignment({
    required String userId,
    required String nickname,
    required String displayName,
    required String avatarUrl,
    required String rozet,
    required List<String> taskIds,
    required String updatedBy,
  }) async {
    final normalizedTasks = normalizeAdminTaskIds(taskIds);
    await _ref.doc(userId.trim()).set(<String, dynamic>{
      'userId': userId.trim(),
      'nickname': nickname.trim(),
      'displayName': displayName.trim(),
      'avatarUrl': avatarUrl.trim(),
      'rozet': rozet.trim(),
      'taskIds': normalizedTasks,
      'updatedBy': updatedBy.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clearAssignment(String userId) async {
    if (userId.trim().isEmpty) return;
    await _ref.doc(userId.trim()).delete();
  }
}
