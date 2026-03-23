part of 'account_center_view.dart';

extension AccountCenterViewContentPart on AccountCenterView {
  Widget _buildContent(
    BuildContext context,
    List<StoredAccount> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAccountsSection(context, items),
        const SizedBox(height: 18),
        _SessionSecuritySection(
          accountCenter: accountCenter,
        ),
        const SizedBox(height: 18),
        _buildPersonalDetailsContent(),
        if (!_isLoggedIn) const SizedBox(height: 0),
      ],
    );
  }
}
