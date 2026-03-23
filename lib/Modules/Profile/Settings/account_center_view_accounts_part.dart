part of 'account_center_view.dart';

extension AccountCenterViewAccountsPart on AccountCenterView {
  Widget _buildAccountsSection(
    BuildContext context,
    List<StoredAccount> items,
  ) {
    return _buildAccountsSectionBody(context, items);
  }
}
