part of 'account_center_view.dart';

extension AccountCenterViewAccountIdentityPart on _AccountRow {
  Widget _buildAccountIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildAccountUsername(),
            RozetContent(
              size: 17,
              userID: account.uid,
              rozetValue: account.rozet,
            ),
          ],
        ),
        if (account.hasDistinctAccountCenterDisplayName) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            account.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ],
      ],
    );
  }
}
