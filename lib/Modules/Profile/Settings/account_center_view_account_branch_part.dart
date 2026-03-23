part of 'account_center_view.dart';

extension AccountCenterViewAccountBranchPart on AccountCenterView {
  Future<void> _continueWithAccountBranch({
    required String currentUid,
    required StoredAccount account,
  }) async {
    if (_hasPasswordProvider(account)) {
      await _continueWithPasswordProviderAccount(account);
      return;
    }

    await _continueWithNonPasswordProviderAccount(
      currentUid: currentUid,
      account: account,
    );
  }
}
