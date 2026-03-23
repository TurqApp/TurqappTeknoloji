part of 'account_center_view.dart';

extension AccountCenterViewAvatarPart on AccountCenterView {
  Widget _avatar(StoredAccount account) {
    final avatarUrl = account.avatarUrl.trim();
    if (avatarUrl.isEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.black.withAlpha(18),
        child: Text(
          account.accountCenterAvatarFallbackInitial,
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'MontserratBold',
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.black12,
      backgroundImage: CachedNetworkImageProvider(avatarUrl),
    );
  }
}

extension AccountCenterViewAccountDataPart on StoredAccount {
  String get accountCenterNormalizedUsername => username.trim();

  String get accountCenterNormalizedDisplayName => displayName.trim();

  String get accountCenterPrimaryLabel =>
      accountCenterNormalizedUsername.isNotEmpty ? username : displayName;

  bool get hasDistinctAccountCenterDisplayName =>
      accountCenterNormalizedDisplayName.isNotEmpty &&
      accountCenterNormalizedDisplayName != accountCenterNormalizedUsername;

  String get accountCenterAvatarFallbackInitial =>
      accountCenterNormalizedDisplayName.isNotEmpty
          ? accountCenterNormalizedDisplayName[0].toUpperCase()
          : '@';
}
