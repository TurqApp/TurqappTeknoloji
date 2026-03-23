part of 'policy_detail_view.dart';

extension _PolicyDetailViewShellPart on PolicyDetailView {
  Widget _buildPolicyDetailShell(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: BackButtons(text: policy.title),
            ),
            Expanded(child: _buildPolicyDetailContent()),
          ],
        ),
      ),
    );
  }
}
