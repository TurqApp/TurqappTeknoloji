part of 'account_center_view.dart';

extension AccountCenterViewActionsPart on AccountCenterView {
  Future<void> _continueWithAccount(StoredAccount account) async {
    final currentUid = _currentUid;
    if (_handleActiveAccountGuard(
      currentUid: currentUid,
      account: account,
    )) {
      return;
    }

    await _continueWithAccountBranch(
      currentUid: currentUid,
      account: account,
    );
  }
}
