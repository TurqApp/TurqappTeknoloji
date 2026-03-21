import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Modules/Profile/AddressSelector/address_selector.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv.dart';
import 'package:turqappv2/Modules/Profile/DeleteAccount/delete_account.dart';
import 'package:turqappv2/Modules/Profile/EditProfile/edit_profile_controller.dart';
import 'package:turqappv2/Modules/Profile/EditorEmail/editor_email.dart';
import 'package:turqappv2/Modules/Profile/EditorNickname/editor_nickname.dart';
import 'package:turqappv2/Modules/Profile/EditorPhoneNumber/editor_phone_number.dart';
import 'package:turqappv2/Modules/Profile/JobSelector/job_selector.dart';
import 'package:turqappv2/Modules/Profile/ProfileContact/profile_contact.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_links.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:turqappv2/Core/Widgets/cached_user_avatar.dart';
import 'package:turqappv2/Core/Buttons/turq_app_toggle.dart';

import '../BiographyMaker/biography_maker.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late final EditProfileController controller;
  late final String _controllerTag;
  final CurrentUserService currentUserService = CurrentUserService.instance;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'edit_profile_${identityHashCode(this)}';
    controller = Get.put(EditProfileController(), tag: _controllerTag);
  }

  @override
  void dispose() {
    if (Get.isRegistered<EditProfileController>(tag: _controllerTag) &&
        identical(
          Get.find<EditProfileController>(tag: _controllerTag),
          controller,
        )) {
      Get.delete<EditProfileController>(tag: _controllerTag);
    }
    super.dispose();
  }

  String get _avatarUrl => currentUserService.avatarUrl.trim();
  String get _nickname => currentUserService.nickname;
  String get _email {
    final primary = currentUserService.email.trim();
    if (primary.isNotEmpty) return primary;
    return controller.email.value;
  }

  String _formatDisplayPhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('+')) return trimmed;
    if (trimmed.startsWith('0')) return '+9$trimmed';
    return '+90$trimmed';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'edit_profile.title'.tr),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Obx(() {
                                    final preview =
                                        controller.croppedImage.value;

                                    return ClipOval(
                                      child: SizedBox(
                                        width: (Get.width * 0.31)
                                            .clamp(96.0, 120.0),
                                        height: (Get.width * 0.31)
                                            .clamp(96.0, 120.0),
                                        child: preview != null
                                            ? Image.memory(
                                                preview,
                                                fit: BoxFit.cover,
                                              )
                                            : (_avatarUrl.isNotEmpty
                                                ? CachedNetworkImage(
                                                    memCacheHeight: 400,
                                                    imageUrl: _avatarUrl,
                                                    fit: BoxFit.cover,
                                                  )
                                                : const Center(
                                                    child: DefaultAvatar(
                                                      radius: 56,
                                                    ),
                                                  )),
                                      ),
                                    );
                                  }),
                                  PullDownButton(
                                    key: ValueKey(_avatarUrl),
                                    itemBuilder: (context) => [
                                      PullDownMenuItem(
                                        onTap: () => controller.pickImage(
                                          source: ImageSource.camera,
                                        ),
                                        title: 'profile_photo.camera'.tr,
                                        icon: CupertinoIcons.camera,
                                      ),
                                      PullDownMenuItem(
                                        onTap: () => controller.pickImage(
                                          source: ImageSource.gallery,
                                        ),
                                        title: 'profile_photo.gallery'.tr,
                                        icon: CupertinoIcons.photo,
                                      ),
                                      if (controller.hasCustomProfilePhoto)
                                        PullDownMenuItem(
                                          onTap: controller.removeProfilePhoto,
                                          title: 'common.remove'.tr,
                                          icon: CupertinoIcons.trash,
                                        ),
                                    ],
                                    buttonBuilder: (context, showMenu) =>
                                        GestureDetector(
                                      onTap: showMenu,
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.pink,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          CupertinoIcons.pencil,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          15.ph,
                          Row(
                            children: [
                              Expanded(
                                child:
                                    Divider(color: Colors.grey.withAlpha(100)),
                              ),
                              12.pw,
                              Text(
                                'edit_profile.personal_info'.tr,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                              12.pw,
                              Expanded(
                                child:
                                    Divider(color: Colors.grey.withAlpha(100)),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                    ),
                                    child: TextField(
                                      controller:
                                          controller.firstNameController,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(20),
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[A-Za-zÇçĞğİıÖöŞşÜü\s]'),
                                        ),
                                      ],
                                      decoration: InputDecoration(
                                        hintText:
                                            'edit_profile.first_name_hint'.tr,
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                          fontFamily: "MontserratMedium",
                                        ),
                                        border: InputBorder.none,
                                      ),
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                    ),
                                    child: TextField(
                                      controller: controller.lastNameController,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(20),
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[A-Za-zÇçĞğİıÖöŞşÜü\s]'),
                                        ),
                                      ],
                                      decoration: InputDecoration(
                                        hintText:
                                            'edit_profile.last_name_hint'.tr,
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                          fontFamily: "MontserratMedium",
                                        ),
                                        border: InputBorder.none,
                                      ),
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () {
                                Get.to(() => EditorNickname())?.then((_) {
                                  currentUserService.forceRefresh();
                                });
                              },
                              child: Container(
                                height: 50,
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "@$_nickname",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                      Text(
                                        'common.change'.tr,
                                        style: TextStyle(
                                          color: Colors.blueAccent,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Obx(() {
                              final verified =
                                  currentUserService.emailVerifiedRx.value;
                              return GestureDetector(
                                onTap: () {
                                  if (!verified) {
                                    Get.to(() => EditorEmail());
                                  }
                                },
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _email,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontFamily: "MontserratMedium",
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        if (verified)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                CupertinoIcons
                                                    .checkmark_seal_fill,
                                                color: Colors.green,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'common.verified'.tr,
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 14,
                                                  fontFamily:
                                                      "MontserratMedium",
                                                ),
                                              ),
                                            ],
                                          )
                                        else
                                          Text(
                                            'common.verify'.tr,
                                            style: const TextStyle(
                                              color: Colors.blueAccent,
                                              fontSize: 15,
                                              fontFamily: "MontserratMedium",
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Obx(() {
                              final currentUser =
                                  currentUserService.currentUserRx.value;
                              final reactivePhone =
                                  controller.phoneNumber.value.trim();
                              final resolvedPhone =
                                  (currentUser?.phoneNumber.trim().isNotEmpty ==
                                          true)
                                      ? currentUser!.phoneNumber.trim()
                                      : reactivePhone;
                              final displayPhone =
                                  _formatDisplayPhone(resolvedPhone);
                              return GestureDetector(
                                onTap: () {
                                  Get.to(() => EditorPhoneNumber())?.then((_) {
                                    currentUserService.forceRefresh();
                                  });
                                },
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            displayPhone.isNotEmpty
                                                ? displayPhone
                                                : 'common.not_specified'.tr,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                              fontFamily: "MontserratMedium",
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'common.change'.tr,
                                          style: const TextStyle(
                                            color: Colors.blueAccent,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                      15.ph,
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: Colors.grey.withAlpha(100)),
                          ),
                          12.pw,
                          Text(
                            'edit_profile.other_info'.tr,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontFamily: "MontserratBold",
                            ),
                          ),
                          12.pw,
                          Expanded(
                              child:
                                  Divider(color: Colors.grey.withAlpha(100))),
                        ],
                      ),
                      SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () async {
                            final currentPrivacy = currentUserService.isPrivate;
                            await currentUserService
                                .updateFields({"isPrivate": !currentPrivacy});
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.03),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(
                                          CupertinoIcons.lock,
                                          color: Colors.black,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'edit_profile.privacy'.tr,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Obx(
                                    () => TurqAppToggle(
                                      isOn: currentUserService.currentUserRx
                                              .value?.gizliHesap ==
                                          true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Get.to(() => SocialMediaLinks());
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.03),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.link,
                                          color: Colors.black,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'edit_profile.links'.tr,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Get.to(() => BiographyMaker());
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.03),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.text_alignleft,
                                          color: Colors.black,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'biography.title'.tr,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Get.to(() => JobSelector())?.then((_) {
                              currentUserService.forceRefresh();
                            });
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.03),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.bag,
                                          color: Colors.black,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'job_selector.title'.tr,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Get.to(() => ProfileContact());
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.03),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.at,
                                          color: Colors.black,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'edit_profile.contact_info'.tr,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Get.to(() => AddressSelector());
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.03),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.map_pin_ellipse,
                                          color: Colors.black,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'edit_profile.address_info'.tr,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            Get.to(() => Cv());
                          },
                          child: Container(
                            height: 50,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.03),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          CupertinoIcons.doc_person,
                                          color: Colors.black,
                                          size: 20,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'edit_profile.career_profile'.tr,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      _updating
                          ? Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                              ),
                              child: const CupertinoActivityIndicator(
                                  color: Colors.white),
                            )
                          : TurqAppButton(
                              onTap: () async {
                                if (_updating) return;
                                setState(() => _updating = true);
                                await controller.updateProfileInfo();
                                if (!mounted) return;
                                setState(() => _updating = false);
                              },
                              text: 'common.update'.tr,
                            ),
                      12.ph,
                      GestureDetector(
                        onTap: () {
                          Get.to(() => DeleteAccount());
                        },
                        child: Text(
                          'edit_profile.delete_account'.tr,
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                              fontFamily: "Montserrat"),
                        ),
                      ),
                      12.ph,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
