part of 'account_center_view.dart';

extension AccountCenterViewAccountNameRowPart on _AccountRow {
  Widget _buildAccountNameRow() {
    return Row(
      children: [
        Flexible(
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
        ),
        RozetContent(
          size: 17,
          userID: account.uid,
          rozetValue: account.rozet,
        ),
      ],
    );
  }
}
