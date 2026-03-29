part of 'social_profile.dart';

extension _SocialProfileHeaderActionsPart on _SocialProfileState {
  Widget buildPostNotificationHeaderButton() {
    return Obx(() {
      final canShow = controller.complatedCheck.value &&
          controller.takipEdiyorum.value &&
          _myUserId.isNotEmpty &&
          _myUserId != widget.userID &&
          !controller.isBlockedByCurrentViewer(widget.userID);
      if (!canShow) return const SizedBox.shrink();

      final enabled = controller.postNotificationsEnabled.value;
      final loading = controller.postNotificationsLoading.value;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppHeaderActionButton(
            onTap: loading ? null : _onPostNotificationPressed,
            surfaceColor: const Color(0xFFFFFFFF),
            child: loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.bell,
                        color: Colors.black,
                        size: AppIconSurface.kIconSize,
                      ),
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: enabled ? Colors.green : Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.add,
                              size: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: AppIconSurface.kGap),
        ],
      );
    });
  }

  Future<void> _onPostNotificationPressed() async {
    if (controller.postNotificationsLoading.value) return;
    final messaging = FirebaseMessaging.instance;
    var settings = await messaging.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }
    final canNotify = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!canNotify) {
      await _showPostNotificationPermissionDialog();
      return;
    }
    await _showPostNotificationOptionsSheet();
  }

  Future<void> _showPostNotificationPermissionDialog() async {
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: const Text('Bildirim ayarlarını aç'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '@${controller.nickname.value} gönderi yayınladığında bildirim almak için cihaz ayarlarında bildirimleri açman gerek.',
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await openAppSettings();
              },
              isDefaultAction: true,
              child: const Text('Ayarlar ve gizlilik'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('İptal et'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPostNotificationOptionsSheet() async {
    final enabled = controller.postNotificationsEnabled.value;
    final actionLabel = enabled ? 'Kapat' : 'Aç';
    final actionBody = enabled
        ? '@${controller.nickname.value} kullanıcısının tüm gönderi bildirimlerini kapatmak istediğinizden emin misiniz?'
        : '@${controller.nickname.value} kullanıcısının tüm gönderi bildirimlerini açmak istediğinizden emin misiniz?';
    await showCupertinoDialog<void>(
      context: context,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: const Text('Tüm gönderiler'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(actionBody),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await controller.togglePostNotifications();
              },
              isDestructiveAction: enabled,
              child: Text(actionLabel),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Vazgeç'),
            ),
          ],
        );
      },
    );
  }

  Widget followButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final showEmail = controller.mailIzin.value &&
            controller.email.value.isNotEmpty;
        final showCall = controller.aramaIzin.value &&
            controller.phoneNumber.value.isNotEmpty;
        final canContact = showEmail || showCall;
        final stackContact =
            canContact && (constraints.maxWidth < 280 || textScale > 1.2);
        final double buttonWidth =
            stackContact ? constraints.maxWidth : (constraints.maxWidth - 24) / 3;

        Widget buildButton({
          required Widget child,
          required VoidCallback? onPressed,
          required Color backgroundColor,
        }) {
          return SizedBox(
            width: buttonWidth,
            child: TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                backgroundColor: backgroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: Size.zero,
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: SizedBox(
                height: 36,
                child: Center(child: child),
              ),
            ),
          );
        }

        final followButton = Obx(
          () => buildButton(
            onPressed: controller.followLoading.value
                ? null
                : () {
                    if (controller.takipEdiyorum.value == false) {
                      controller.toggleFollowStatus();
                    } else {
                      noYesAlert(
                        title: 'profile.unfollow_title'.tr,
                        message: 'profile.unfollow_body'.trParams({
                          'nickname': controller.nickname.value,
                        }),
                        yesText: 'profile.unfollow_confirm'.tr,
                        onYesPressed: () {
                          _setCenteredIndex(-1);
                          controller.toggleFollowStatus();
                        },
                      );
                    }
                  },
            backgroundColor: controller.takipEdiyorum.value
                ? Colors.grey.withAlpha(50)
                : Colors.black,
            child: controller.followLoading.value
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        controller.takipEdiyorum.value
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  )
                : Text(
                    controller.takipEdiyorum.value
                        ? 'profile.following_status'.tr
                        : 'profile.follow_button'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: controller.takipEdiyorum.value
                          ? Colors.black
                          : Colors.white,
                      fontSize: 13,
                      fontFamily: "MontserratBold",
                    ),
                  ),
          ),
        );

        final messageButton = buildButton(
          onPressed: () async {
            final sohbet = chatListingController.list.firstWhereOrNull(
              (val) => val.userID == widget.userID,
            );
            final prevIndex = controller.lastCenteredIndex;
            controller.lastCenteredIndex = prevIndex;
            controller.centeredIndex.value = -1;

            if (sohbet != null) {
              await Get.to(
                () => ChatView(
                  chatID: sohbet.chatID,
                  userID: widget.userID,
                  isNewChat: false,
                  openKeyboard: true,
                ),
              );
              controller.resumeCenteredPost();
            } else {
              final chatId = buildConversationId(
                _myUserId,
                widget.userID,
              );
              await Get.to(
                () => ChatView(
                  chatID: chatId,
                  userID: widget.userID,
                  isNewChat: true,
                  openKeyboard: true,
                ),
              )?.then((_) {
                chatListingController.getList();
              });
              controller.resumeCenteredPost();
            }
          },
          backgroundColor: Colors.grey.withAlpha(50),
          child: Text(
            'common.message'.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontFamily: "MontserratBold",
            ),
          ),
        );

        final contactButton = canContact
            ? buildButton(
                onPressed: () async {
                  Get.bottomSheet(
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withAlpha(100),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Container(
                              alignment: Alignment.center,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'profile.contact_options'.tr,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ),
                            if (showEmail)
                              TextButton(
                                onPressed: () async {
                                  final mail = controller.email.value;
                                  final uri = Uri.parse('mailto:$mail');
                                  await launchUrl(uri);
                                  Get.back();
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 12,
                                  ),
                                  backgroundColor: Colors.grey.withAlpha(50),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.mail,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        controller.email.value,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'MontserratBold',
                                          fontSize: 15,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (showEmail && showCall)
                              const SizedBox(height: 10),
                            if (showCall)
                              TextButton(
                                onPressed: () async {
                                  final tel = controller.phoneNumber.value;
                                  final uri = Uri.parse('tel:0$tel');
                                  await launchUrl(uri);
                                  Get.back();
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 12,
                                  ),
                                  backgroundColor: Colors.grey.withAlpha(50),
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.phone,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '+90${controller.phoneNumber.value}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'MontserratBold',
                                          fontSize: 15,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    isScrollControlled: true,
                  );
                },
                backgroundColor: Colors.grey.withAlpha(50),
                child: Text(
                  'common.contact'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontFamily: 'MontserratBold',
                  ),
                ),
              )
            : const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                followButton,
                messageButton,
                if (!stackContact && canContact) contactButton,
              ],
            ),
            if (stackContact && canContact) ...[
              const SizedBox(height: 12),
              contactButton,
            ],
          ],
        );
      },
    );
  }

  Widget unblockButton() {
    return TextButton(
      onPressed: () {
        controller.unblock();
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.grey.withAlpha(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size.zero,
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: SizedBox(
        height: 36,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'profile.unblock'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontFamily: "MontserratBold",
              ),
            ),
          ),
        ),
      ),
    );
  }
}
