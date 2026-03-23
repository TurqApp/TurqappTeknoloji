part of 'account_center_view.dart';

extension AccountCenterViewPersonalEmptyPart on _PersonalDetailsCard {
  Widget _buildPersonalEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Text(
        'account_center.no_personal_detail'.tr,
        style: TextStyle(
          color: Colors.black54,
          fontSize: 14,
          fontFamily: 'MontserratMedium',
        ),
      ),
    );
  }
}
