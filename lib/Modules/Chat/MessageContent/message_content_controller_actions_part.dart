part of 'message_content_controller.dart';

extension MessageContentControllerActionsPart on MessageContentController {
  Future<void> showMapsSheet() async {
    Get.bottomSheet(
      barrierColor: Colors.black.withAlpha(50),
      SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'chat.open_in_maps'.tr,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse(
                    "https://www.google.com/maps/search/?api=1&query=${model.lat},${model.long}",
                  );
                  if (await canLaunchUrl(url)) {
                    await confirmAndLaunchExternalUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                  Get.back();
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: Image.asset("assets/icons/googlemaps.webp"),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'chat.open_in_google_maps'.tr,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (Platform.isIOS)
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse(
                      "http://maps.apple.com/?q=${model.lat},${model.long}",
                    );
                    if (await canLaunchUrl(url)) {
                      await confirmAndLaunchExternalUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                    Get.back();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: Image.asset("assets/icons/applemaps.webp"),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'chat.open_in_apple_maps'.tr,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse(
                    "yandexmaps://maps.yandex.ru/?ll=${model.long},${model.lat}&z=10",
                  );
                  if (await canLaunchUrl(url)) {
                    await launchUrl(
                      url,
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    final webUrl = Uri.parse(
                      "https://yandex.com/maps/?ll=${model.long},${model.lat}&z=10",
                    );
                    if (await canLaunchUrl(webUrl)) {
                      await confirmAndLaunchExternalUrl(
                        webUrl,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  }
                  Get.back();
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Image.asset("assets/icons/yandexmaps.webp"),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'chat.open_in_yandex_maps'.tr,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
    );
  }

  Future<void> addContact() async {
    await ContactAdd.addContact(
      Contact(
        firstname: model.kisiAdSoyad,
        phone: model.kisiTelefon.startsWith("5")
            ? "+90${model.kisiTelefon}"
            : model.kisiTelefon,
      ),
    );
  }

  Future<void> showContactInfo() async {
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'chat.contact_info'.tr,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                width: 70,
                height: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.grey,
                  size: 30,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                model.kisiAdSoyad,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratBold",
                ),
              ),
              Text(
                model.kisiTelefon,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: addContact,
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Text(
                          'chat.save_to_contacts'.tr,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        launchUrl(Uri.parse("tel://${model.kisiTelefon}"));
                      },
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Text(
                            'chat.call'.tr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> deleteMessage() async {
    if (model.source == "preview") return;
    final currentUid = CurrentUserService.instance.effectiveUserId.trim();
    if (currentUid.isEmpty) return;

    await showActionSheet(
      title: 'chat.delete_message_title'.tr,
      message: 'chat.delete_message_body'.tr,
      titleColor: Colors.black,
      messageColor: Colors.grey.shade600,
      cancelText: 'common.cancel'.tr,
      cancelButtonColor: Colors.blueAccent,
      actions: [
        {
          'text': 'chat.delete_for_me'.tr,
          'isDestructive': true,
          'color': Colors.red,
          'onPressed': () async {
            await _conversationRepository.deleteMessageForUser(
              chatId: mainID,
              messageId: model.rawDocID,
              currentUid: currentUid,
            );
          },
        },
        {
          'text': 'chat.delete_for_everyone'.tr,
          'isDestructive': false,
          'color': Colors.red,
          'onPressed': () async {
            await _conversationRepository.unsendMessage(
              chatId: mainID,
              messageId: model.rawDocID,
            );
          },
        },
      ],
    );
  }

  Future<void> likeImage() async {
    final currentUserID = CurrentUserService.instance.effectiveUserId.trim();
    if (currentUserID.isEmpty) return;
    await _conversationRepository.toggleMessageLike(
      chatId: mainID,
      messageId: model.rawDocID,
      currentUid: currentUserID,
      isLiked: model.begeniler.contains(currentUserID),
    );
  }

  Future<void> deleteSingleImage(String imgUrl) async {
    if (model.source == "preview") return;
    await noYesAlert(
      title: 'chat.delete_photo_title'.tr,
      message: 'chat.delete_photo_body'.tr,
      cancelText: 'common.cancel'.tr,
      yesText: 'chat.delete_photo_confirm'.tr,
      yesButtonColor: CupertinoColors.destructiveRed,
      onYesPressed: () async {
        await _conversationRepository.removeMessageImage(
          chatId: mainID,
          messageId: model.rawDocID,
          imgUrl: imgUrl,
        );
      },
    );
  }
}
