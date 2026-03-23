part of 'my_admin_approval_results_view.dart';

Stream<QuerySnapshot<Map<String, dynamic>>> _watchOwnApprovals(String uid) {
  final repo = AdminApprovalRepository.ensure();
  return repo.watchOwnApprovals(uid);
}
