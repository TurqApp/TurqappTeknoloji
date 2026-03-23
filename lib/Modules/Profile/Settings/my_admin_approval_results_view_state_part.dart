part of 'my_admin_approval_results_view.dart';

extension MyAdminApprovalResultsViewStatePart on MyAdminApprovalResultsView {
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
