part of 'my_admin_approval_results_view.dart';

extension MyAdminApprovalResultsViewContentPart on MyAdminApprovalResultsView {
  Widget _buildApprovalList(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        return _ApprovalResultTile(data: docs[index].data());
      },
    );
  }
}
