part of 'account_center_view.dart';

extension AccountCenterViewUsernameSwitchPart on AccountCenterView {
  Future<void> _continueWithUsernameAccount(StoredAccount account) async {
    await Get.offAll(
      () => SignIn(
        initialIdentifier: account.username,
        storedAccountUid: account.uid,
      ),
    );
  }
}
