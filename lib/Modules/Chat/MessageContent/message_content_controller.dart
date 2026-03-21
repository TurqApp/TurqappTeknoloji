import 'dart:async';
import 'dart:io';
import 'package:contact_add/contact.dart';
import 'package:contact_add/contact_add.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Core/Repositories/notify_lookup_repository.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/BottomSheets/show_action_sheet.dart';
import 'package:turqappv2/Core/Helpers/safe_external_link_guard.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Models/message_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Models/posts_model.dart';

class MessageContentController extends GetxController {
  static MessageContentController ensure({
    required MessageModel model,
    required String mainID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MessageContentController(model: model, mainID: mainID),
      tag: tag,
      permanent: permanent,
    );
  }

  static MessageContentController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MessageContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MessageContentController>(tag: tag);
  }

  final MessageModel model;
  final String mainID;

  var nickname = "".obs;
  var avatarUrl = "".obs;

  var currentIndex = 0.obs;
  var showAllImages = false.obs;
  RxList<String> imageUrls = <String>[].obs;
  var postModel = Rx<PostsModel?>(null);

  MessageContentController({
    required this.model,
    required this.mainID,
  });

  var postNickname = "".obs;
  var postPfImage = "".obs;
  final ConversationRepository _conversationRepository =
      ConversationRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  @override
  void onInit() {
    super.onInit();

    // model.imgs atanır
    imageUrls.assignAll(model.imgs);

    // kullanıcı verisini al
    unawaited(_loadMessageUser());

    if (model.postID != "") {
      getPost();
    }
  }

  Future<void> _loadMessageUser() async {
    final user = await _userSummaryResolver.resolve(
      model.userID,
      preferCache: true,
    );
    if (user == null) return;
    nickname.value = user.nickname.isNotEmpty
        ? user.nickname
        : (user.username.isNotEmpty ? user.username : user.displayName);
    avatarUrl.value = user.avatarUrl;
  }

  Future<void> showMapsSheet() async {
    Get.bottomSheet(
      barrierColor: Colors.black.withAlpha(50),
      SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'chat.open_in_maps'.tr,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse(
                      "https://www.google.com/maps/search/?api=1&query=${model.lat},${model.long}");
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
                      SizedBox(width: 12),
                      Text(
                        'chat.open_in_google_maps'.tr,
                        style: TextStyle(
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
                        "http://maps.apple.com/?q=${model.lat},${model.long}");
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
                        SizedBox(width: 12),
                        Text(
                          'chat.open_in_apple_maps'.tr,
                          style: TextStyle(
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
                      "yandexmaps://maps.yandex.ru/?ll=${model.long},${model.lat}&z=10");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    final webUrl = Uri.parse(
                        "https://yandex.com/maps/?ll=${model.long},${model.lat}&z=10");
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
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Image.asset("assets/icons/yandexmaps.webp"),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'chat.open_in_yandex_maps'.tr,
                        style: TextStyle(
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
    await ContactAdd.addContact(Contact(
        firstname: model.kisiAdSoyad,
        phone: model.kisiTelefon.startsWith("5")
            ? "+90${model.kisiTelefon}"
            : model.kisiTelefon));
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
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold"),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Container(
                width: 70,
                height: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.grey,
                  size: 30,
                ),
              ),
              SizedBox(height: 15),
              Text(
                model.kisiAdSoyad,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold"),
              ),
              Text(
                model.kisiTelefon,
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
              SizedBox(height: 25),
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
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratMedium"),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
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
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontFamily: "MontserratMedium"),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> deleteMessage() async {
    if (model.source == "preview") return;
    final currentUid = CurrentUserService.instance.userId.trim();
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
    final currentUserID = CurrentUserService.instance.userId.trim();
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

  Future<void> getPost() async {
    final lookup =
        await NotifyLookupRepository.ensure().getPostLookup(model.postID);
    if (!lookup.exists || lookup.model == null) {
      postModel.value = PostsModel.empty();
      return;
    }
    postModel.value = lookup.model;
    final user = await _userSummaryResolver.resolve(
      lookup.model!.userID,
      preferCache: true,
    );
    if (user == null) return;
    postNickname.value = user.preferredName;
    postPfImage.value = user.avatarUrl;
  }
}
