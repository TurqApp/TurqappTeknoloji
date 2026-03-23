part of 'account_center_view.dart';

extension AccountCenterViewPersonalRowBodyPart on _PersonalDetailRow {
  Widget _buildPersonalRowBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(child: _buildPersonalRowContent()),
          _buildAccountCenterChevron(),
        ],
      ),
    );
  }
}
