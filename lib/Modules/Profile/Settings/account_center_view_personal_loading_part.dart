part of 'account_center_view.dart';

extension AccountCenterViewPersonalLoadingPart on _PersonalDetailsSection {
  Widget _buildPersonalLoadingState() {
    return _buildAccountCenterCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: const CupertinoActivityIndicator(),
    );
  }
}
