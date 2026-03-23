part of 'account_center_view.dart';

extension AccountCenterViewAccountsHeaderPart on AccountCenterView {
  Widget _buildAccountsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAccountsTitle(),
          const SizedBox(height: 18),
          _buildAccountsSectionLabel(),
        ],
      ),
    );
  }
}
