part of 'account_center_view.dart';

extension AccountCenterViewAccountsListItemPart on AccountCenterView {
  Widget _buildAccountsListItem(
    BuildContext context,
    StoredAccount account,
  ) {
    return _AccountRow(
      account: account,
      avatar: _avatar(account),
      onTap: () => _continueWithAccount(account),
      onLongPress: () => _confirmRemoveAccount(
        context,
        account,
      ),
    );
  }
}
