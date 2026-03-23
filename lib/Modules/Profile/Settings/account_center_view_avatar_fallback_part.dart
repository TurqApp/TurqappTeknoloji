part of 'account_center_view.dart';

extension AccountCenterViewAvatarFallbackPart on AccountCenterView {
  Widget _buildFallbackAvatar(StoredAccount account) {
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
}
