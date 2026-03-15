import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
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
  final SignInController _signInController = Get.put(SignInController());
  final Future<void> _initFuture = AccountCenterService.ensure().init();

  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  CurrentUserService get _currentUserService => CurrentUserService.instance;

  Future<void> _continueWithAccount(StoredAccount account) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid == account.uid) {
      AppSnackbar('Aktif Hesap', '@${account.username} zaten aktif.');
      return;
    }

    if (account.hasPasswordProvider) {
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
        'Gecis yapilamadi',
        'Bu hesap icin once bir kez normal giris yapilmasi gerekiyor.',
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
            BackButtons(text: 'Hesap Merkezi'),
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
                          const Padding(
                            padding: EdgeInsets.fromLTRB(4, 4, 4, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profiller ve giris bilgileri',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 26,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Bu cihazda kullandigin hesaplari burada gorebilir, istedigin hesabla devam edebilir veya yeni bir hesap ekleyebilirsin.',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    height: 1.45,
                                    fontFamily: 'MontserratMedium',
                                  ),
                                ),
                                SizedBox(height: 18),
                                Text(
                                  'Hesaplar',
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
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 22,
                                    ),
                                    child: Text(
                                      'Henuz bu cihaza eklenmis bir hesap yok.',
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
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 18,
                                          ),
                                          child: Text(
                                            'Hesap ekle',
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
                          const Padding(
                            padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
                            child: Text(
                              'Kisisel detaylar',
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
          title: 'Iletisim bilgileri',
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
        child: const Text(
          'Henuz gosterilecek bir kisisel detay yok.',
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
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
    return (currentUserService.currentUser?.email ??
            FirebaseAuth.instance.currentUser?.email ??
            '')
        .trim();
  }

  String _phoneValue(CurrentUserService currentUserService) {
    return (currentUserService.currentUser?.phoneNumber ??
            FirebaseAuth.instance.currentUser?.phoneNumber ??
            '')
        .trim();
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
            BackButtons(text: 'Iletisim Bilgileri'),
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
                          title: 'E-posta',
                          value: email.isNotEmpty ? email : 'E-posta eklenmedi',
                          isVerified: emailVerified,
                          verifiedLabel: 'Onayli',
                          pendingLabel: 'Onayla',
                          onTap: () => Get.to(() => EditorEmail()),
                        ),
                        const Divider(height: 1, indent: 18, endIndent: 18),
                        _ContactStatusRow(
                          icon: CupertinoIcons.phone,
                          title: 'Telefon',
                          value: phone.isNotEmpty ? phone : 'Telefon eklenmedi',
                          isVerified: phoneVerified,
                          verifiedLabel: 'Onayli',
                          pendingLabel: 'Onaysiz',
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
  });

  final StoredAccount account;
  final Widget avatar;
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
              avatar,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.username.trim().isNotEmpty
                          ? account.username
                          : account.displayName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'MontserratBold',
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
