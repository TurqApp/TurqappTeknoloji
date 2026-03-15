import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/stored_account.dart';
import 'package:turqappv2/Modules/SignIn/sign_in.dart';
import 'package:turqappv2/Services/account_center_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AccountCenterView extends StatelessWidget {
  AccountCenterView({super.key});

  final AccountCenterService accountCenter = AccountCenterService.ensure();
  final UserRepository _userRepository = UserRepository.ensure();

  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  String _subtitleFor(StoredAccount account, String currentUid) {
    if (account.uid == currentUid) return 'Bu cihazda aktif hesap';
    if (account.requiresReauth) return 'Yeniden giriş gerekli';
    if (!account.isSessionValid) return 'Devam etmek için giriş yap';
    return 'Bu cihazda kayıtlı hesap';
  }

  String _providerLabel(StoredAccount account) {
    final providers =
        account.providers.map((e) => e.trim()).where((e) => e.isNotEmpty);
    if (providers.isEmpty) return 'Diger';
    final labels = providers.map((provider) {
      switch (provider) {
        case 'password':
          return 'E-posta';
        case 'phone':
          return 'Telefon';
        default:
          return 'Diger';
      }
    }).toSet();
    return labels.join(' • ');
  }

  String _continueMessageFor(StoredAccount account) {
    final provider = account.primaryProvider;
    switch (provider) {
      case 'phone':
        return '@${account.username} telefon ile kayitli gorunuyor. Mevcut oturum kapatilacak ve yeniden giris icin hesap secilecek.';
      case 'password':
        return 'Mevcut oturum kapatılacak. Ardından @${account.username} için giriş ekranı açılacak.';
      default:
        return '@${account.username} için manuel yeniden giriş gerekecek. Mevcut oturum kapatıldıktan sonra giriş ekranı açılacak.';
    }
  }

  String _lastUsedLabel(StoredAccount account) {
    final lastUsedAt = account.lastUsedAt;
    if (lastUsedAt <= 0) return 'Kullanim zamani bilinmiyor';
    final now = DateTime.now();
    final time = DateTime.fromMillisecondsSinceEpoch(lastUsedAt);
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Az once kullanildi';
    if (diff.inHours < 1) return '${diff.inMinutes} dk once kullanildi';
    if (diff.inDays < 1) return '${diff.inHours} sa once kullanildi';
    if (diff.inDays < 7) return '${diff.inDays} gun once kullanildi';
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    final year = time.year.toString();
    return '$day.$month.$year tarihinde kullanildi';
  }

  String _lastSuccessfulLabel(StoredAccount account) {
    if (account.lastSuccessfulSignInAt <= 0) return 'Basarili giris kaydi yok';
    final time =
        DateTime.fromMillisecondsSinceEpoch(account.lastSuccessfulSignInAt);
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return 'Son basarili giris: $day.$month $hour:$minute';
  }

  Future<void> _continueWithAccount(StoredAccount account) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (currentUid == account.uid) {
      AppSnackbar('Aktif Hesap', '@${account.username} zaten aktif.');
      return;
    }

    if (currentUid.isNotEmpty) {
      noYesAlert(
        title: 'Hesaba Geç',
        message: _continueMessageFor(account),
        onYesPressed: () async {
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

          await Get.offAll(
            () => SignIn(
              initialIdentifier: account.username,
              storedAccountUid: account.uid,
            ),
          );
        },
        yesText: 'Devam Et',
        cancelText: 'Vazgeç',
      );
      return;
    }

    await Get.offAll(
      () => SignIn(
        initialIdentifier: account.username,
        storedAccountUid: account.uid,
      ),
    );
  }

  Future<void> _removeAccount(StoredAccount account) async {
    final activeUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isActive = activeUid == account.uid;
    noYesAlert(
      title: 'Hesabı Kaldır',
      message: isActive
          ? '@${account.username} bu cihazdan kaldırılacak. Aktif oturum da kapatılacak.'
          : '@${account.username} bu cihazdaki kayıtlı hesap listesinden kaldırılacak.',
      onYesPressed: () async {
        if (isActive) {
          try {
            await _userRepository.updateUserFields(account.uid, {'token': ''});
          } catch (_) {}
          try {
            await CurrentUserService.instance.logout();
            await FirebaseAuth.instance.signOut();
          } catch (_) {}
        }
        await accountCenter.removeAccount(account.uid);
        if (isActive) {
          await Get.offAll(() => SignIn());
        } else {
          AppSnackbar('Kaldırıldı', '@${account.username} cihaz listesinden silindi.');
        }
      },
      yesText: 'Kaldır',
      cancelText: 'Vazgeç',
    );
  }

  Widget _avatar(StoredAccount account) {
    final avatarUrl = account.avatarUrl.trim();
    if (avatarUrl.isEmpty) {
      return CircleAvatar(
        radius: 26,
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
      radius: 26,
      backgroundColor: Colors.black12,
      backgroundImage: CachedNetworkImageProvider(avatarUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'Hesap Merkezi'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Obx(() {
                  final items = accountCenter.accounts.toList(growable: false);
                  final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'Bu cihazda kayıtlı hesap bulunmuyor.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    );
                  }

                  return ListView(
                    children: [
                      const Text(
                        'Bu cihazda daha once kullanilan hesaplar burada tutulur. Medya cache korunur, hesap state ise kullanici bazli ayrilir.',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          height: 1.4,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final account in items) ...[
                        ...() {
                          final siblings = items
                              .where((item) => item.isPinned == account.isPinned)
                              .toList(growable: false);
                          final siblingIndex = siblings.indexWhere(
                            (item) => item.uid == account.uid,
                          );
                          final canMoveUp = siblingIndex > 0;
                          final canMoveDown =
                              siblingIndex >= 0 && siblingIndex < siblings.length - 1;
                          return <Widget>[
                        _AccountTile(
                          account: account,
                          isActive: currentUid == account.uid,
                          isLastUsed: accountCenter.lastUsedUid.value == account.uid,
                          canMoveUp: canMoveUp,
                          canMoveDown: canMoveDown,
                          subtitle: _subtitleFor(account, currentUid),
                          providerLabel: _providerLabel(account),
                          lastUsedLabel: _lastUsedLabel(account),
                          lastSuccessfulLabel: _lastSuccessfulLabel(account),
                          onTap: () => _continueWithAccount(account),
                          onRemove: () => _removeAccount(account),
                          onTogglePinned: () => accountCenter.togglePinned(account.uid),
                          onMoveUp: () => accountCenter.moveAccount(account.uid, up: true),
                          onMoveDown: () => accountCenter.moveAccount(account.uid, up: false),
                          avatar: _avatar(account),
                        ),
                        const SizedBox(height: 10),
                          ];
                        }(),
                      ],
                      if (_isLoggedIn) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Get.to(() => SignIn()),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black.withAlpha(14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text(
                              'Farklı Bir Hesap Ekle',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
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

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.isActive,
    required this.isLastUsed,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.subtitle,
    required this.providerLabel,
    required this.lastUsedLabel,
    required this.lastSuccessfulLabel,
    required this.onTap,
    required this.onRemove,
    required this.onTogglePinned,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.avatar,
  });

  final StoredAccount account;
  final bool isActive;
  final bool isLastUsed;
  final bool canMoveUp;
  final bool canMoveDown;
  final String subtitle;
  final String providerLabel;
  final String lastUsedLabel;
  final String lastSuccessfulLabel;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onTogglePinned;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final Widget avatar;

  Color get _badgeColor {
    if (isActive) return Colors.green.shade600;
    if (account.requiresReauth || !account.isSessionValid) {
      return Colors.orange.shade700;
    }
    return Colors.blueGrey.shade600;
  }

  String get _badgeText {
    if (isActive) return 'Aktif';
    if (account.requiresReauth || !account.isSessionValid) {
      return 'Giriş Gerekli';
    }
    return 'Kayitli';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.withAlpha(12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.displayName.trim().isNotEmpty
                          ? account.displayName
                          : '@${account.username}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${account.username}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      providerLabel,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lastUsedLabel,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lastSuccessfulLabel,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _badgeColor.withAlpha(22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _badgeText,
                            style: TextStyle(
                              color: _badgeColor,
                              fontSize: 11,
                              fontFamily: 'MontserratBold',
                            ),
                          ),
                        ),
                        if (isLastUsed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Son Kullanilan',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ),
                        if (account.isPinned)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withAlpha(40),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Sabit',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    onPressed: onTogglePinned,
                    icon: Icon(
                      account.isPinned
                          ? CupertinoIcons.pin_fill
                          : CupertinoIcons.pin,
                      color: Colors.black54,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: canMoveUp ? onMoveUp : null,
                    icon: Icon(
                      CupertinoIcons.chevron_up,
                      color: canMoveUp ? Colors.black45 : Colors.black26,
                      size: 18,
                    ),
                  ),
                  IconButton(
                    onPressed: canMoveDown ? onMoveDown : null,
                    icon: Icon(
                      CupertinoIcons.chevron_down,
                      color: canMoveDown ? Colors.black45 : Colors.black26,
                      size: 18,
                    ),
                  ),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(
                      CupertinoIcons.trash,
                      color: Colors.black45,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
