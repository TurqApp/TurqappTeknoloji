part of 'account_center_view.dart';

extension AccountCenterViewAccountIdentityPart on _AccountRow {
  Widget _buildAccountIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAccountNameRow(),
        ..._buildAccountDisplayName(),
      ],
    );
  }
}
