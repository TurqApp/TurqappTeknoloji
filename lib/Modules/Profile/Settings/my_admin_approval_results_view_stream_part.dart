part of 'my_admin_approval_results_view.dart';

extension MyAdminApprovalResultsViewStreamPart on MyAdminApprovalResultsView {
  Widget _buildApprovalStream(String uid) {
    final repo = AdminApprovalRepository.ensure();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repo.watchOwnApprovals(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _buildMessageState(
            'admin.my_approvals.load_failed'.tr,
          );
        }
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) {
          return _buildMessageState(
            'admin.my_approvals.empty'.tr,
          );
        }
        return _buildApprovalList(docs);
      },
    );
  }
}
