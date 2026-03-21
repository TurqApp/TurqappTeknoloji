import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/rozet_content.dart';
import 'package:turqappv2/Models/stored_account.dart';
import 'package:turqappv2/Modules/Profile/EditorEmail/editor_email.dart';
import 'package:turqappv2/Modules/Profile/EditorPhoneNumber/editor_phone_number.dart';
import 'package:turqappv2/Modules/SignIn/sign_in.dart';
import 'package:turqappv2/Modules/SignIn/sign_in_controller.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AccountCenterView extends StatelessWidget {
  AccountCenterView({super.key});

  final AccountCenterService accountCenter = AccountCenterService.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  final SignInController _signInController = SignInController();
  final Future<void> _initFuture = AccountCenterService.ensure().init();

  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  CurrentUserService get _currentUserService => CurrentUserService.instance;

  Future<void> _continueWithAccount(StoredAccount account) async {
    final currentUid = _currentUserService.userId.trim();
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
        final identifier =
            await _signInController.preferredIdentifierForStoredAccount(account);
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
    final currentUid = _currentUserService.userId.trim();
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

  Widget _avatar(StoredAccount account) {
    final avatarUrl = account.avatarUrl.trim();
    if (avatarUrl.isEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: Colors.black.withAlpha(18),
        child: Text(
          account.displayName.trim().isNotEmpty
              ? account.displayName.trim()[0].toUpperCase()
              : '@',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'settings.account_center'.tr),
            Expanded(
              child: FutureBuilder<void>(
                future: _initFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Obx(() {
                      final items = accountCenter.accounts.toList(growable: false);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(4, 4, 4, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'account_center.header_title'.tr,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 26,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                                SizedBox(height: 18),
                                Text(
                                  'account_center.accounts'.tr,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: items.isEmpty
                                ? Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 22,
                                    ),
                                    child: Text(
                                      'account_center.no_accounts'.tr,
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
                                        fontFamily: 'MontserratMedium',
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: [
                                      for (var i = 0; i < items.length; i++) ...[
                                        _AccountRow(
                                          account: items[i],
                                          avatar: _avatar(items[i]),
                                          onTap: () => _continueWithAccount(items[i]),
                                          onLongPress: () =>
                                              _confirmRemoveAccount(
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
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              bottom: Radius.circular(18),
                                            ),
                                        onTap: () => Get.to(() => SignIn()),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 18,
                                          ),
                                          child: Text(
                                            'account_center.add_account'.tr,
                                            style: TextStyle(
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
                          const SizedBox(height: 18),
                          _SessionSecuritySection(
                            accountCenter: accountCenter,
                          ),
                          const SizedBox(height: 18),
                          Padding(
                            padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
                            child: Text(
                              'account_center.personal_details'.tr,
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ),
                          _PersonalDetailsSection(
                            currentUserService: _currentUserService,
                            userRepository: _userRepository,
                            onContactTap: () =>
                                Get.to(() => const _ContactDetailsView()),
                          ),
                          if (!_isLoggedIn) const SizedBox(height: 0),
                        ],
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionSecuritySection extends StatelessWidget {
  const _SessionSecuritySection({
    required this.accountCenter,
  });

  final AccountCenterService accountCenter;

  @override
  Widget build(BuildContext context) {
    final uid = CurrentUserService.instance.userId.trim();
    if (uid.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text(
            'account_center.security'.tr,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontFamily: 'MontserratBold',
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black12),
          ),
          child: StreamBuilder<Map<String, dynamic>?>(
            stream: UserRepository.ensure().watchUserRaw(uid),
            builder: (context, snapshot) {
              final enabled =
                  (snapshot.data?['singleDeviceSessionEnabled'] ?? false) == true;
              return SwitchListTile.adaptive(
                value: enabled,
                onChanged: (value) async {
                  await accountCenter.setSingleDeviceSessionEnabled(value);
                  AppSnackbar(
                    'settings.account_center'.tr,
                    value
                        ? 'account_center.single_device_enabled'.tr
                        : 'account_center.single_device_disabled'.tr,
                  );
                },
                title: Text(
                  'account_center.single_device_title'.tr,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'MontserratBold',
                  ),
                ),
                subtitle: Text(
                  'account_center.single_device_desc'.tr,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontFamily: 'MontserratMedium',
                    height: 1.35,
                  ),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PersonalDetailsCard extends StatelessWidget {
  const _PersonalDetailsCard({
    required this.contactDetails,
    required this.onContactTap,
  });

  final String? contactDetails;
  final VoidCallback onContactTap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (contactDetails != null)
        _PersonalDetailRow(
          title: 'account_center.contact_info'.tr,
          value: contactDetails!,
          onTap: onContactTap,
        ),
    ];

    if (rows.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Text(
          'account_center.no_personal_detail'.tr,
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
            fontFamily: 'MontserratMedium',
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              const Divider(height: 1, indent: 18, endIndent: 18),
          ],
        ],
      ),
    );
  }
}

class _PersonalDetailsSection extends StatelessWidget {
  const _PersonalDetailsSection({
    required this.currentUserService,
    required this.userRepository,
    required this.onContactTap,
  });

  final CurrentUserService currentUserService;
  final UserRepository userRepository;
  final VoidCallback onContactTap;

  Future<String?> _loadContactDetails() async {
    final current = currentUserService.currentUser;
    final authUser = FirebaseAuth.instance.currentUser;
    final parts = <String>[];

    final directEmail = (current?.email ?? authUser?.email ?? '').trim();
    final directPhone =
        (current?.phoneNumber ?? authUser?.phoneNumber ?? '').trim();
    if (directEmail.isNotEmpty) parts.add(directEmail);
    if (directPhone.isNotEmpty) parts.add(directPhone);
    if (parts.isNotEmpty) return parts.join(', ');

    final uid = authUser?.uid ?? '';
    if (uid.isEmpty) return null;
    final raw = await userRepository.getUserRaw(uid, preferCache: true);
    if (raw == null) return null;

    final fallbackParts = <String>[];
    final email = (raw['email'] ?? '').toString().trim();
    final phone = (raw['phoneNumber'] ?? '').toString().trim();
    if (email.isNotEmpty) fallbackParts.add(email);
    if (phone.isNotEmpty) fallbackParts.add(phone);
    if (fallbackParts.isEmpty) return null;
    return fallbackParts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = CurrentUserService.instance.userId.trim();
    return FutureBuilder<String?>(
      key: ValueKey(currentUid),
      future: _loadContactDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            !(snapshot.hasData && (snapshot.data?.isNotEmpty ?? false))) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: const CupertinoActivityIndicator(),
          );
        }
        return _PersonalDetailsCard(
          contactDetails: snapshot.data,
          onContactTap: onContactTap,
        );
      },
    );
  }
}

class _PersonalDetailRow extends StatelessWidget {
  const _PersonalDetailRow({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
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
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.black38,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactDetailsView extends StatelessWidget {
  const _ContactDetailsView();

  String _emailValue(CurrentUserService currentUserService) {
    return currentUserService.email.trim();
  }

  String _phoneValue(CurrentUserService currentUserService) {
    return currentUserService.phoneNumber.trim();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserService = CurrentUserService.instance;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'account_center.contact_details'.tr),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(() {
                  final email = _emailValue(currentUserService);
                  final phone = _phoneValue(currentUserService);
                  final emailVerified = currentUserService.emailVerifiedRx.value;
                  final phoneVerified = phone.isNotEmpty;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Column(
                      children: [
                        _ContactStatusRow(
                          icon: CupertinoIcons.mail,
                          title: 'account_center.email'.tr,
                          value: email.isNotEmpty
                              ? email
                              : 'account_center.email_missing'.tr,
                          isVerified: emailVerified,
                          verifiedLabel: 'account_center.verified'.tr,
                          pendingLabel: 'account_center.verify'.tr,
                          onTap: () => Get.to(() => EditorEmail()),
                        ),
                        const Divider(height: 1, indent: 18, endIndent: 18),
                        _ContactStatusRow(
                          icon: CupertinoIcons.phone,
                          title: 'account_center.phone'.tr,
                          value: phone.isNotEmpty
                              ? phone
                              : 'account_center.phone_missing'.tr,
                          isVerified: phoneVerified,
                          verifiedLabel: 'account_center.verified'.tr,
                          pendingLabel: 'account_center.unverified'.tr,
                          onTap: () => Get.to(() => EditorPhoneNumber()),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactStatusRow extends StatelessWidget {
  const _ContactStatusRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.isVerified,
    required this.verifiedLabel,
    required this.pendingLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool isVerified;
  final String verifiedLabel;
  final String pendingLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = isVerified ? Colors.green : Colors.blueAccent;
    final statusText = isVerified ? verifiedLabel : pendingLabel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.black54, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
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
                ),
              ),
              if (isVerified)
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 14,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ],
                )
              else
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 14,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
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
                            account.username.trim().isNotEmpty
                                ? account.username
                                : account.displayName,
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
                    if (account.displayName.trim().isNotEmpty &&
                        account.displayName.trim() !=
                            account.username.trim()) ...[
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
              const Icon(
                CupertinoIcons.chevron_right,
                color: Colors.black38,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
