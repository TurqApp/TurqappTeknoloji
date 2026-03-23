part of 'account_center_view.dart';

extension AccountCenterViewAccountsListPart on AccountCenterView {
  Widget _buildAccountsList(
    BuildContext context,
    List<StoredAccount> items,
  ) {
    return Column(children: _buildAccountsListChildren(context, items));
  }
}
