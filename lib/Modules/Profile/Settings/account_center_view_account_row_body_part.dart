part of 'account_center_view.dart';

extension AccountCenterViewAccountRowBodyPart on _AccountRow {
  Widget _buildAccountRowBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 14),
          Expanded(child: _buildAccountIdentity()),
          _buildAccountCenterChevron(),
        ],
      ),
    );
  }
}
