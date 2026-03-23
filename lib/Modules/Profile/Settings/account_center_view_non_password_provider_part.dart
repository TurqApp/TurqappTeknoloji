part of 'account_center_view.dart';

extension AccountCenterViewNonPasswordProviderPart on AccountCenterView {
  Future<void> _continueWithNonPasswordProviderAccount({
    required String currentUid,
    required StoredAccount account,
  }) async {
    if (currentUid.isNotEmpty) {
      await _clearCurrentSession(currentUid);
    }

    await _continueWithUsernameAccount(account);
  }
}
