part of 'account_center_view.dart';

extension AccountCenterViewAccountsListPart on AccountCenterView {
  Widget _buildAccountsList(
    BuildContext context,
    List<StoredAccount> items,
  ) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _AccountRow(
            account: items[i],
            avatar: _avatar(items[i]),
            onTap: () => _continueWithAccount(items[i]),
            onLongPress: () => _confirmRemoveAccount(
              context,
              items[i],
            ),
          ),
          if (i != items.length - 1)
            const Divider(
              height: 1,
              indent: 84,
              endIndent: 16,
            ),
        ],
        _buildAddAccountAction(),
      ],
    );
  }
}
