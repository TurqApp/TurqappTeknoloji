part of 'account_center_view.dart';

extension AccountCenterViewAccountUsernamePart on _AccountRow {
  Widget _buildAccountUsername() {
    return Flexible(
      child: Text(
        account.username.trim().isNotEmpty
            ? account.username
            : account.displayName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }
}
