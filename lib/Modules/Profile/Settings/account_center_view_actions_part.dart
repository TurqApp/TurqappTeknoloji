part of 'account_center_view.dart';

extension AccountCenterViewActionsPart on AccountCenterView {
  Future<void> _continueWithAccount(StoredAccount account) async {
    final currentUid = _currentUid;
    if (currentUid == account.uid) {
      AppSnackbar(
        'account_center.active_account_title'.tr,
        'account_center.active_account_body'
            .trParams(<String, String>{'username': account.username}),
      );
      return;
    }

    if (account.hasPasswordProvider) {
      if (account.requiresReauth) {
        final identifier = await _signInController
            .preferredIdentifierForStoredAccount(account);
        await Get.offAll(
          () => SignIn(
            initialIdentifier: identifier,
            storedAccountUid: account.uid,
          ),
        );
        AppSnackbar(
          'account_center.reauth_title'.tr,
          'account_center.reauth_body'
              .trParams(<String, String>{'username': account.username}),
        );
        return;
      }
      Get.dialog(
        const Center(child: CupertinoActivityIndicator()),
        barrierDismissible: false,
      );
      final switched = await _signInController.signInWithStoredAccount(account);
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      if (switched) return;
      AppSnackbar(
        'account_center.switch_failed_title'.tr,
        'account_center.switch_failed_body'.tr,
      );
      return;
    }

    if (currentUid.isNotEmpty) {
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

    await Get.offAll(
      () => SignIn(
        initialIdentifier: account.username,
        storedAccountUid: account.uid,
      ),
    );
  }

  Future<void> _confirmRemoveAccount(
    BuildContext context,
    StoredAccount account,
  ) async {
    final currentUid = _currentUid;
    if (currentUid == account.uid) {
      AppSnackbar(
        'account_center.active_account_title'.tr,
        'account_center.remove_active_forbidden'.tr,
      );
      return;
    }

    final shouldRemove = await showCupertinoDialog<bool>(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: Text('account_center.remove_account_title'.tr),
            content: Text(
              'account_center.remove_account_body'
                  .trParams(<String, String>{'username': account.username}),
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text('common.cancel'.tr),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text('common.delete'.tr),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldRemove) return;
    await accountCenter.removeAccount(account.uid);
    AppSnackbar(
      'common.success'.tr,
      'account_center.account_removed'
          .trParams(<String, String>{'username': account.username}),
    );
  }
}
