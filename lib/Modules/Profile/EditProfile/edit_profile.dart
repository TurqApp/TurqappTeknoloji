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
import 'package:turqappv2/Modules/Profile/JobSelector/job_selector.dart';
import 'package:turqappv2/Modules/Profile/ProfileContact/profile_contact.dart';
import 'package:turqappv2/Modules/Profile/SocialMediaLinks/social_media_links.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/firebase_my_store.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

import '../BiographyMaker/biography_maker.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late final EditProfileController controller;
  late final FirebaseMyStore user;
  final CurrentUserService currentUserService = CurrentUserService.instance;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(EditProfileController());
    user = Get.find<FirebaseMyStore>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Profil Bilgileri"),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Obx(() {
                        return Column(
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
                                          width: 120,
                                          height: 120,
                                          child: preview != null
                                              ? Image.memory(
                                                  preview,
                                                  fit: BoxFit.cover,
                                                )
                                              : (user.avatarUrl.value != ""
                                                  ? CachedNetworkImage(
                                                      memCacheHeight: 400,
                                                      imageUrl:
                                                          user.avatarUrl.value,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Center(
                                                      child:
                                                          CupertinoActivityIndicator(
                                                        color: Colors.grey,
                                                      ),
                                                    )),
                                        ),
                                      );
                                    }),
                                    PullDownButton(
                                      key: ValueKey(user.avatarUrl.value),
                                      itemBuilder: (context) => [
                                        PullDownMenuItem(
                                          onTap: () => controller.pickImage(
                                            source: ImageSource.camera,
                                          ),
                                          title: 'Kameradan Çek',
                                          icon: CupertinoIcons.camera,
                                        ),
                                        PullDownMenuItem(
                                          onTap: () => controller.pickImage(
                                            source: ImageSource.gallery,
                                          ),
                                          title: 'Galeriden Seç',
                                          icon: CupertinoIcons.photo,
                                        ),
                                        if (controller.hasCustomProfilePhoto)
                                          PullDownMenuItem(
                                            onTap:
                                                controller.removeProfilePhoto,
                                            title: 'Kaldır',
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
                                  child: Divider(
                                      color: Colors.grey.withAlpha(100)),
                                ),
                                12.pw,
                                Text(
                                  "Kişisel Bilgiler",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                    fontFamily: "MontserratBold",
                                  ),
                                ),
                                12.pw,
                                Expanded(
                                  child: Divider(
                                      color: Colors.grey.withAlpha(100)),
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
                                      color:
                                          Colors.black.withValues(alpha: 0.03),
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
                                          hintText: "Adınız",
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
                                      color:
                                          Colors.black.withValues(alpha: 0.03),
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
                                            controller.lastNameController,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(20),
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[A-Za-zÇçĞğİıÖöŞşÜü\s]'),
                                          ),
                                        ],
                                        decoration: InputDecoration(
                                          hintText: "Soyadınız",
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
                                          "@${user.nickname.value}",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                        Text(
                                          "Değiştir",
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
                              child: GestureDetector(
                                onTap: () {
                                  if (!currentUserService
                                      .emailVerifiedRx.value) {
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
                                        Text(
                                          user.email.value,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                        Obx(() {
                                          final verified = currentUserService
                                              .emailVerifiedRx.value;
                                          if (verified) {
                                            return const Row(
                                              children: [
                                                Icon(
                                                  CupertinoIcons
                                                      .checkmark_seal_fill,
                                                  color: Colors.green,
                                                  size: 18,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  "Onaylı",
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontSize: 14,
                                                    fontFamily:
                                                        "MontserratMedium",
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                          return const Text(
                                            "Onayla",
                                            style: TextStyle(
                                              color: Colors.blueAccent,
                                              fontSize: 15,
                                              fontFamily: "MontserratMedium",
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: GestureDetector(
                                onTap: () {},
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
                                          "+90${user.phoneNumber.value}",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                        const Row(
                                          children: [
                                            Icon(
                                              CupertinoIcons
                                                  .checkmark_seal_fill,
                                              color: Colors.green,
                                              size: 18,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              "Onaylı",
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 14,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      15.ph,
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: Colors.grey.withAlpha(100)),
                          ),
                          12.pw,
                          Text(
                            "Diğer Bilgiler",
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
                                          "Bağlantılar",
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
                                          "Biyografi",
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
                                          "Meslek & Kategori",
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
                                          "İletişim Bilgileri",
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
                                          "Adres Bilgileri",
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
                                          "Özgeçmiş (CV)",
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
                              text: "Güncelle",
                            ),
                      12.ph,
                      GestureDetector(
                        onTap: () {
                          Get.to(() => DeleteAccount());
                        },
                        child: Text(
                          "Hesabını Sil",
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
