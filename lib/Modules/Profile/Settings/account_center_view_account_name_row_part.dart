part of 'account_center_view.dart';

extension AccountCenterViewAccountNameRowPart on _AccountRow {
  Widget _buildAccountNameRow() {
    return Row(
      children: [
        _buildAccountUsername(),
        RozetContent(
          size: 17,
          userID: account.uid,
          rozetValue: account.rozet,
        ),
      ],
    );
  }
}
