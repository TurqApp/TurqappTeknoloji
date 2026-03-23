part of 'account_center_view.dart';

extension AccountCenterViewAccountIdentityPart on _AccountRow {
  Widget _buildAccountIdentity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAccountNameRow(),
        if (account.displayName.trim().isNotEmpty &&
            account.displayName.trim() != account.username.trim()) ...[
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
