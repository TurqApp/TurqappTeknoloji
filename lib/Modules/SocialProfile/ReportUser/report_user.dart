import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';

import '../../../Core/strings.dart';
import 'report_user_controller.dart';

class ReportUser extends StatelessWidget {
  final String userID;
  final String postID;
  final String commentID;
  ReportUser(
      {super.key,
      required this.userID,
      required this.postID,
      required this.commentID});
  late final ReportUserController controller;
  @override
  Widget build(BuildContext context) {
    controller = Get.put(ReportUserController(
        userID: userID, postID: postID, commentID: commentID));
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(children: [
              if (controller.step.value == 0.50)
                BackButtons(text: "Şikayet Et")
              else
                GestureDetector(
                  onTap: () {
                    controller.step.value = 0.5;
                  },
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.arrow_left,
                        color: Colors.black,
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Text(
                        "Şikayet Et",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 25,
                            fontFamily: "MontserratBold"),
                      )
                    ],
                  ),
                )
            ]),
            Obx(() {
              return LinearProgressIndicator(
                color: Colors.black,
                minHeight: 1,
                value: controller.step.value,
                backgroundColor: Colors.grey.withAlpha(20),
              );
            }),
            Expanded(
              child: SingleChildScrollView(
                child: Obx(() {
                  return controller.step.value == 0.5 ? step1() : step2();
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget step1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Text(
                "Şikayet Edilecek Kullanıcı",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: "MontserratBold",
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(12)),
              border: Border.all(color: Colors.blueAccent),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 55,
                      height: 55,
                      child: controller.avatarUrl.value != ""
                          ? CachedNetworkImage(
                              imageUrl: controller.avatarUrl.value,
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: CupertinoActivityIndicator(
                                  color: Colors.black)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.nickname.value,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          controller.fullName.value,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            "Ne tür bir sorun bildiriyorsun?",
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: "MontserratBold",
            ),
          ),
        ),
        SizedBox(height: 12),
        const SizedBox(height: 15),
        for (var item in reportSelections)
          Padding(
            padding: const EdgeInsets.only(bottom: 15, left: 15, right: 15),
            child: Material(
              color: Colors.transparent, // Ripple efektinin düzgün çıkması için
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  controller.selectedKey.value = item.key;
                  controller.selectedTitle.value = item.title;
                  controller.selectedDesc.value = item.description;
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: controller.selectedTitle.value == item.title
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                              if (controller.selectedTitle.value == item.title)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.description,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: controller.selectedTitle.value == item.title
                                ? Colors.black
                                : Colors.white,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(15)),
                            border: Border.all(
                              color:
                                  controller.selectedTitle.value == item.title
                                      ? Colors.black
                                      : Colors.grey,
                            ),
                          ),
                          child: controller.selectedTitle.value == item.title
                              ? const Icon(
                                  CupertinoIcons.checkmark,
                                  color: Colors.white,
                                  size: 12,
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 25),
          child: TurqAppButton(
            bgColor: Colors.black,
            onTap: () {
              if (controller.selectedKey.value.isEmpty) {
                return;
              }
              controller.step.value = 1.0;
            },
            text: "Devam Et",
          ),
        )
      ],
    );
  }

  Widget step2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "TurqApp'i herkes için daha iyi bir hâle getirmemize katkıda bulunduğunuz için teşekkür ederiz!",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 25,
                    fontFamily: "MontserratBold"),
              ),
              const SizedBox(
                height: 4,
              ),
              const Text(
                "Vakitinizin değerli olduğunu biliyoruz. Bize vakit ayırdığınız için teşekkür ederiz.",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
              const SizedBox(
                height: 15,
              ),
              const Text(
                "Nasıl ilerliyoruz?",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold"),
              ),
              const SizedBox(
                height: 4,
              ),
              const Text(
                "Bildirimin bize ulaştı. Bildirilen profili akıştan gizleyeceğiz.",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
              const SizedBox(
                height: 15,
              ),
              const Text(
                "Şimdi sırada ne var?",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold"),
              ),
              const SizedBox(
                height: 4,
              ),
              const Text(
                "Ekibimiz bu profili bir kaç gün içersinde inceleyecek. Bir kural ihlali tespit ettiği taktirde bu hesap kısıtlanacaktır. Eğer bir ihlal tespit edilemez ise bir çok kez geçersiz şikayetler ilettiyseniz, hesabınız kısıtlanacaktır.",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
              const SizedBox(
                height: 15,
              ),
              const Text(
                "Eğer isterseniz?",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold"),
              ),
              const SizedBox(
                height: 4,
              ),
              const Text(
                "Bu profili engelleyebilirsiniz. Engellemeniz durumunda, bu kullanıcı bir daha akışınızda hiçbir şekilde görünmeyecektir.",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
              const SizedBox(
                height: 15,
              ),
              if (!controller.blockedUser.value)
                GestureDetector(
                  onTap: () {
                    controller.block();
                  },
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(12)),
                        border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.5))),
                    child: Text(
                      "@${controller.nickname.value} kullanıcısını engelle",
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium"),
                    ),
                  ),
                )
              else
                Text(
                  "@${controller.nickname.value} engellendi!",
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                    fontStyle: FontStyle.italic, // Metni italik yapar
                    decoration: TextDecoration.underline, // Altını çizer
                  ),
                ),
              const SizedBox(
                height: 15,
              ),
              Text(
                "${controller.nickname.value} adlı kullanıcını seni takip etmesini, mesaj göndermesini engelle. Herkese açık gönderilerini görebilir ancak seninle etkileşim kuramaz. Bununla birlikte ${controller.nickname.value} kişisinin gönderilerini göremezsin.",
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontFamily: "MontserratMedium"),
              ),
              SizedBox(
                height: 12,
              ),
              Obx(() {
                return TurqAppButton(
                  onTap: () {
                    controller.report();
                  },
                  text: controller.isSubmitting.value
                      ? "Gönderiliyor..."
                      : "Bitti",
                );
              }),
              SizedBox(
                height: 12,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
