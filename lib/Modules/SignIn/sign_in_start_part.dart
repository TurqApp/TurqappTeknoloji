part of 'sign_in.dart';

extension SignInStartPart on _SignInState {
  Widget startScreen() {
    final accountCenter = ensureAccountCenterService();
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _brandTypewriter(),
                        const SizedBox(height: 10),
                        Text(
                          'login.tagline'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ],
                    ),
                  ),
                  Obx(() {
                    final accounts = accountCenter.accounts.toList(
                      growable: false,
                    );
                    if (accounts.isEmpty) return const SizedBox.shrink();
                    final visible = accounts.take(3).toList(growable: false);
                    return Column(
                      children: [
                        if (accountCenter.lastUsedAccount != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Text(
                                  'login.device_accounts'.tr,
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        for (final account in visible) ...[
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () async {
                                await controller.continueWithStoredAccount(
                                  account,
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withAlpha(16),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.black12,
                                      backgroundImage:
                                          account.avatarUrl.trim().isEmpty
                                              ? null
                                              : NetworkImage(
                                                  account.avatarUrl.trim(),
                                                ),
                                      child: account.avatarUrl.trim().isEmpty
                                          ? Text(
                                              account.displayName
                                                      .trim()
                                                      .isNotEmpty
                                                  ? account.displayName
                                                      .trim()[0]
                                                      .toUpperCase()
                                                  : '@',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontFamily: 'MontserratBold',
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            account.displayName
                                                    .trim()
                                                    .isNotEmpty
                                                ? account.displayName
                                                : '@${account.username}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontFamily: 'MontserratBold',
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '@${account.username}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12,
                                              fontFamily: 'MontserratMedium',
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            accountCenter.lastUsedUid.value ==
                                                    account.uid
                                                ? 'login.last_used'.tr
                                                : 'login.saved_account'.tr,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.black45,
                                              fontSize: 11,
                                              fontFamily:
                                                  'MontserratMedium',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      CupertinoIcons.chevron_right,
                                      color: Colors.black38,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                      ],
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: const ValueKey('login_button'),
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              controller.clearStoredAccountContext();
                              controller.selection.value = 1;
                            },
                            child: Ink(
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 50,
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      'login.sign_in'.tr,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontFamily: "MontserratBold",
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            controller.clearStoredAccountContext();
                            controller.signupPoliciesAccepted.value = false;
                            controller.selection.value = 2;
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 50),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(50),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Text(
                                'login.create_account'.tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "© TurqApp A.Ş.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
