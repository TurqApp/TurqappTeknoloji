import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AdminApprovalRepository extends GetxService {
  static const String _adminConfigDocId = 'admin';

  static AdminApprovalRepository ensure() {
    if (Get.isRegistered<AdminApprovalRepository>()) {
      return Get.find<AdminApprovalRepository>();
    }
    return Get.put(AdminApprovalRepository(), permanent: true);
  }

  CollectionReference<Map<String, dynamic>> get _ref =>
      FirebaseFirestore.instance
          .collection('adminConfig')
          .doc(_adminConfigDocId)
          .collection('adminApprovals');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchApprovals() {
    return _ref.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchOwnApprovals(String uid) {
    if (uid.trim().isEmpty) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return _ref
        .where('createdBy', isEqualTo: uid.trim())
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> createApproval({
    required String type,
    required String title,
    required String summary,
    required String targetUserId,
    required String targetNickname,
    required Map<String, dynamic> payload,
  }) async {
    final authUser = FirebaseAuth.instance.currentUser;
    final current = CurrentUserService.instance.currentUser;
    final uid = authUser?.uid ?? '';
    await _ref.add(<String, dynamic>{
      'type': type.trim(),
      'title': title.trim(),
      'summary': summary.trim(),
      'status': 'pending',
      'targetUserId': targetUserId.trim(),
      'targetNickname': targetNickname.trim(),
      'payload': payload,
      'createdBy': uid,
      'createdByNickname': current?.nickname.trim() ?? '',
      'createdByDisplayName': current?.fullName.trim() ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
      'resolvedBy': '',
      'resolvedByNickname': '',
      'rejectionReason': '',
    });
  }

  Future<void> approve(String docId) async {
    final authUser = FirebaseAuth.instance.currentUser;
    final current = CurrentUserService.instance.currentUser;
    await _ref.doc(docId).set(<String, dynamic>{
      'status': 'approved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': authUser?.uid ?? '',
      'resolvedByNickname': current?.nickname.trim() ?? '',
      'rejectionReason': '',
    }, SetOptions(merge: true));
  }

  Future<void> reject(String docId, {String reason = ''}) async {
    final authUser = FirebaseAuth.instance.currentUser;
    final current = CurrentUserService.instance.currentUser;
    await _ref.doc(docId).set(<String, dynamic>{
      'status': 'rejected',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': authUser?.uid ?? '',
      'resolvedByNickname': current?.nickname.trim() ?? '',
      'rejectionReason': reason.trim(),
    }, SetOptions(merge: true));
  }
}
