part of 'account_center_view.dart';

extension AccountCenterViewAccountsCardPart on AccountCenterView {
  Widget _buildAccountsCard(
    BuildContext context,
    List<StoredAccount> items,
  ) {
    return _buildAccountCenterCard(
      child: items.isEmpty
          ? _buildAccountsEmptyState()
          : Column(
              children: [
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
              ],
            ),
    );
  }
}
