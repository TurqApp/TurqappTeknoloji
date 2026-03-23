part of 'my_admin_approval_results_view.dart';

extension MyAdminApprovalResultsViewShellPart on MyAdminApprovalResultsView {
  Widget _buildPage(BuildContext context) {
    final uid = _currentUid;
    final repo = AdminApprovalRepository.ensure();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'admin.my_approvals.title'.tr),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageState(String text) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'MontserratMedium',
          fontSize: 13,
        ),
      ),
    );
  }
}
