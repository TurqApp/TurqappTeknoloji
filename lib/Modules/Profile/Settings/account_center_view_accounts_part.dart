part of 'account_center_view.dart';

extension AccountCenterViewBodyContentPart on AccountCenterView {
  Widget _buildBodyContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Obx(() {
        final items = accountCenter.accounts.toList(growable: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'account_center.accounts'.tr,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontFamily: 'MontserratBold',
                        ),
                      ),
                    ],
                  ),
                ),
                _buildAccountCenterCard(
                  child: items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 22,
                          ),
                          child: _buildAccountCenterEmptyText(
                            'account_center.no_accounts'.tr,
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              _AccountRow(
                                account: items[i],
                                avatar: _avatar(items[i]),
                                onTap: () => _continueWithAccount(items[i]),
                                onLongPress: () => _confirmRemoveAccount(
                                  context,
                                  items[i],
                                ),
                              ),
                              if (i != items.length - 1)
                                const Divider(
                                  height: 1,
                                  indent: 84,
                                  endIndent: 16,
                                ),
                            ],
                            InkWell(
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(18),
                              ),
                              onTap: () => Get.to(() => SignIn()),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 18,
                                ),
                                child: Text(
                                  'account_center.add_account'.tr,
                                  style: const TextStyle(
                                    color: Color(0xFF3797EF),
                                    fontSize: 15,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SessionSecuritySection(
              accountCenter: accountCenter,
            ),
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                  child: Text(
                    'account_center.personal_details'.tr,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
                _PersonalDetailsSection(
                  currentUserService: _currentUserService,
                  userRepository: _userRepository,
                  onContactTap: () => Get.to(() => const _ContactDetailsView()),
                ),
              ],
            ),
            if (!_isLoggedIn) const SizedBox(height: 0),
          ],
        );
      }),
    );
  }

  Future<void> _confirmRemoveAccount(
    BuildContext context,
    StoredAccount account,
  ) async {
    if (_currentUid == account.uid) {
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
      bool switched;
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
        switched = true;
      } else {
        Get.dialog(
          const Center(child: CupertinoActivityIndicator()),
          barrierDismissible: false,
        );
        switched = await _signInController.signInWithStoredAccount(account);
        if (Get.isDialogOpen == true) {
          Get.back();
        }
      }
      if (switched) {
        return;
      }
      if (!account.requiresReauth) {
        AppSnackbar(
          'account_center.switch_failed_title'.tr,
          'account_center.switch_failed_body'.tr,
        );
      }
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
}

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

Widget _buildAccountCenterInfoContent({
  required String title,
  required String value,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontFamily: 'MontserratBold',
        ),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 13,
          fontFamily: 'MontserratMedium',
        ),
      ),
    ],
  );
}

Widget _buildAccountCenterChevron() {
  return const Icon(
    CupertinoIcons.chevron_right,
    color: Colors.black38,
    size: 18,
  );
}

Widget _buildAccountCenterRowShell({
  required Widget child,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    ),
  );
}

Widget _buildAccountCenterEmptyText(String text) {
  return Text(
    text,
    style: const TextStyle(
      color: Colors.black54,
      fontSize: 14,
      fontFamily: 'MontserratMedium',
    ),
  );
}

Widget _buildAccountCenterCard({
  required Widget child,
  EdgeInsetsGeometry? padding,
}) {
  return Container(
    decoration: _buildAccountCenterCardDecoration(),
    padding: padding,
    child: child,
  );
}

BoxDecoration _buildAccountCenterCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.black12),
  );
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.avatar,
    required this.onTap,
    required this.onLongPress,
  });

  final StoredAccount account;
  final Widget avatar;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return _buildAccountCenterRowShell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          account.accountCenterPrimaryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ),
                      RozetContent(
                        size: 17,
                        userID: account.uid,
                        rozetValue: account.rozet,
                      ),
                    ],
                  ),
                  if (account.hasDistinctAccountCenterDisplayName) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(
                      account.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _buildAccountCenterChevron(),
          ],
        ),
      ),
    );
  }
}
