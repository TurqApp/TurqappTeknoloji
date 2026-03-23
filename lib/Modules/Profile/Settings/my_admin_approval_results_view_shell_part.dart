part of 'my_admin_approval_results_view.dart';

extension MyAdminApprovalResultsViewShellPart on MyAdminApprovalResultsView {
  Widget _buildPage(BuildContext context) {
    final uid = _currentUid;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'admin.my_approvals.title'.tr),
            Expanded(
              child: _buildApprovalStream(uid),
            ),
          ],
        ),
      ),
    );
  }
}
