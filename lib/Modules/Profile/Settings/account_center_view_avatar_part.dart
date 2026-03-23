part of 'account_center_view.dart';

extension AccountCenterViewAvatarPart on AccountCenterView {
  Widget _avatar(StoredAccount account) {
    final avatarUrl = account.avatarUrl.trim();
    if (avatarUrl.isEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.black.withAlpha(18),
        child: Text(
          account.displayName.trim().isNotEmpty
              ? account.displayName.trim()[0].toUpperCase()
              : '@',
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
