part of 'account_center_view.dart';

extension AccountCenterViewPersonalEmptyPart on _PersonalDetailsCard {
  Widget _buildPersonalEmptyState() {
    return _buildAccountCenterCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: _buildAccountCenterEmptyText(
        'account_center.no_personal_detail'.tr,
      ),
    );
  }
}
