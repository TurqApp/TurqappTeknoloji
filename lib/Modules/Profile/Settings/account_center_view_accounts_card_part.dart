part of 'account_center_view.dart';

extension AccountCenterViewAccountsCardPart on AccountCenterView {
  Widget _buildAccountsCard(
    BuildContext context,
    List<StoredAccount> items,
  ) {
    return _buildAccountCenterCard(
      child: items.isEmpty
          ? _buildAccountsEmptyState()
          : _buildAccountsList(context, items),
    );
  }
}
