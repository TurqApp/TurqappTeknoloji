part of 'account_center_view.dart';

extension AccountCenterViewAccountDisplayNameTextPart on _AccountRow {
  Widget _buildAccountDisplayNameText() {
    return Text(
      account.displayName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.black54,
        fontSize: 12,
        fontFamily: 'MontserratMedium',
      ),
    );
  }
}
