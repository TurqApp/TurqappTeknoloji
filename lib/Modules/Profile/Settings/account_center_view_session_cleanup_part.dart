part of 'account_center_view.dart';

extension AccountCenterViewSessionCleanupPart on AccountCenterView {
  Future<void> _clearCurrentSession(String currentUid) async {
    try {
      await accountCenter.markSessionState(
        uid: currentUid,
        isSessionValid: false,
      );
      await _userRepository.updateUserFields(currentUid, {'token': ''});
    } catch (_) {}

    try {
      await CurrentUserService.instance.logout();
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }
}
