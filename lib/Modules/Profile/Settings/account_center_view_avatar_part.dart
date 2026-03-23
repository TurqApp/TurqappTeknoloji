part of 'account_center_view.dart';

extension AccountCenterViewAvatarPart on AccountCenterView {
  Widget _avatar(StoredAccount account) {
    final avatarUrl = account.avatarUrl.trim();
    if (avatarUrl.isEmpty) {
      return _buildFallbackAvatar(account);
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.black12,
      backgroundImage: CachedNetworkImageProvider(avatarUrl),
    );
  }
}
