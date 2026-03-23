part of 'account_center_view.dart';

extension AccountCenterViewAccountsBodyPart on AccountCenterView {
  Widget _buildAccountsSectionBody(
    BuildContext context,
    List<StoredAccount> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAccountsHeader(),
        _buildAccountsCard(context, items),
      ],
    );
  }
}
