part of 'account_center_view.dart';

extension AccountCenterViewAccountsListChildrenPart on AccountCenterView {
  List<Widget> _buildAccountsListChildren(
    BuildContext context,
    List<StoredAccount> items,
  ) {
    return [
      for (var i = 0; i < items.length; i++) ...[
        _buildAccountsListItem(context, items[i]),
        if (i != items.length - 1)
          const Divider(
            height: 1,
            indent: 84,
            endIndent: 16,
          ),
      ],
      _buildAddAccountAction(),
    ];
  }
}
