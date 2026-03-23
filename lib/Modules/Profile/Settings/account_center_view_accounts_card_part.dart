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
          ? Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 22,
              ),
              child: Text(
                'account_center.no_accounts'.tr,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  fontFamily: 'MontserratMedium',
                ),
              ),
            )
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
                InkWell(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                  onTap: () => Get.to(() => SignIn()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    child: Text(
                      'account_center.add_account'.tr,
                      style: const TextStyle(
                        color: Color(0xFF3797EF),
                        fontSize: 15,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
