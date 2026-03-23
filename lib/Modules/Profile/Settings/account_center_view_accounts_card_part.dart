part of 'account_center_view.dart';

extension AccountCenterViewAccountsCardPart on AccountCenterView {
  Widget _buildAccountsCard(
    BuildContext context,
    List<StoredAccount> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: items.isEmpty
          ? _buildAccountsEmptyState()
          : Column(
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
            ),
    );
  }
}
