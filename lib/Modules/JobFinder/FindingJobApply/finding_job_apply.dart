import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/turq_app_toggle.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv.dart';

import 'finding_job_apply_controller.dart';

class FindingJobApply extends StatelessWidget {
  FindingJobApply({super.key});
  final controller = Get.put(FindingJobApplyController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(15),
                  child: Row(
                    children: [BackButtons(text: "İş Arıyorum Platformu")],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "İş Arıyorum Platformu Nasıl Çalışır ?",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: "MontserratMedium"),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Text(
                        "Özgeçmişiniz, onayınız doğrultusunda işverenlerle paylaşılacaktır. İşverenler, ilan yayınlamadan önce ihtiyaç duydukları pozisyonlara uygun adayları sistemimiz üzerinden inceleyebilir. Böylece hem işverenler aradıkları çalışanlara daha hızlı ulaşabilir hem de siz iş arayanlar daha kısa sürede iş fırsatlarına erişebilirsiniz. Amacımız, işe alım sürecini her iki taraf için de daha hızlı ve etkili hale getirmektir.",
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: "Montserrat"),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Obx(() {
                        return controller.cvVar.value
                            ? GestureDetector(
                                onTap: () {
                                  controller.isFinding.value =
                                      !controller.isFinding.value;
                                  FirebaseFirestore.instance
                                      .collection("CV")
                                      .doc(FirebaseAuth
                                              .instance.currentUser?.uid ??
                                          '')
                                      .update({
                                    "findingJob": controller.isFinding.value
                                  });
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(20),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(12)),
                                      border: Border.all(
                                          color: Colors.grey.shade300)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "İş Arıyorum",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium"),
                                          ),
                                        ),
                                        TurqAppToggle(
                                            isOn: controller.isFinding.value)
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : GestureDetector(
                                onTap: () {
                                  Get.to(() => Cv());
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(20),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(12)),
                                      border: Border.all(
                                          color: Colors.grey.shade300)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "CV Oluştur",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium"),
                                          ),
                                        ),
                                        Icon(
                                          CupertinoIcons.chevron_right,
                                          size: 20,
                                          color: Colors.blueAccent,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                      })
                    ],
                  ),
                )
              ],
            ),
            Opacity(
              opacity: 0.5,
              child: Transform.translate(
                  offset: Offset(40, 10),
                  child: Image.asset(
                    "assets/images/cv.webp",
                    height: Get.height / 4,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
