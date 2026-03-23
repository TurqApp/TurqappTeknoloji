part of 'account_center_view.dart';

extension AccountCenterViewContentSectionsPart on AccountCenterView {
  List<Widget> _buildContentSections(
    BuildContext context,
    List<StoredAccount> items,
  ) {
    return [
      _buildAccountsSection(context, items),
      const SizedBox(height: 18),
      _SessionSecuritySection(
        accountCenter: accountCenter,
      ),
      const SizedBox(height: 18),
      _buildPersonalDetailsContent(),
      if (!_isLoggedIn) const SizedBox(height: 0),
    ];
  }
}
