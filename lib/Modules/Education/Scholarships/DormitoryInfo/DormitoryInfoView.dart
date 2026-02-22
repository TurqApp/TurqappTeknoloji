import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:turqappv2/Core/BottomSheets/NoYesAlert.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Modules/Education/Scholarships/DormitoryInfo/DormitoryInfoController.dart';

class DormitoryInfoView extends StatelessWidget {
  DormitoryInfoView({super.key});

  final DormitoryInfoController controller = Get.put(DormitoryInfoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: BackButtons(text: "Yurt Bilgileri"),
                ),
                PullDownButton(
                  itemBuilder: (context) => [
                    PullDownMenuItem(
                      title: 'Yurt Bilgilerimi Sıfırla',
                      icon: CupertinoIcons.restart,
                      onTap: () {
                        noYesAlert(
                          title: "Emin misiniz?",
                          message:
                              "Yurt bilgileriniz sıfırlanacak. Bu işlem geri alınamaz.",
                          cancelText: "İptal",
                          yesText: "Sıfırla",
                          yesButtonColor: CupertinoColors.destructiveRed,
                          onYesPressed: () async {
                            controller.yurt.value = "";
                            controller.sehir.value = "Şehir Seç";
                            controller.ilce.value = "İlçe Seç";
                            controller.sub.value = "İdari Seç";
                            controller.listedeYok.value = false;
                            controller.yurtInput.clear();
                            controller.yurtInputText.value = "";
                            controller.yurtSelectionController.clear();

                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .update({"yurt": ""});

                            AppSnackbar(
                              "Başarılı",
                              "Yurt Bilgileriniz sıfırlandı.",
                            );
                          },
                        );
                      },
                    ),
                  ],
                  buttonBuilder: (context, showMenu) => IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: showMenu,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Obx(
                () => controller.isLoading.value
                    ? Center(child: CupertinoActivityIndicator())
                    : SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (controller.yurt.value != "")
                                Container(
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Mevcut Yurt Bilgisi",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratBold",
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          controller.yurt.value,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: controller.showIlSec,
                                      child: Container(
                                        height: 50,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Obx(
                                            () => Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  controller.sehir.value,
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 15,
                                                    fontFamily:
                                                        "MontserratMedium",
                                                  ),
                                                ),
                                                Icon(
                                                  CupertinoIcons.chevron_down,
                                                  size: 20,
                                                  color: Colors.black,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: controller.showIdariSec,
                                      child: Container(
                                        height: 50,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.1),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Obx(
                                            () => Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  controller.capitalize(
                                                    controller.sub.value,
                                                  ),
                                                  style: TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 15,
                                                    fontFamily:
                                                        "MontserratMedium",
                                                  ),
                                                ),
                                                Icon(
                                                  CupertinoIcons.chevron_down,
                                                  size: 20,
                                                  color: Colors.black,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (controller.sehir.value != "Şehir Seç" &&
                                  controller.sub.value != "İdari Seç")
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: GestureDetector(
                                    onTap: controller.showYurtSec,
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                        child: TextField(
                                          controller: controller
                                              .yurtSelectionController,
                                          enabled: false,
                                          decoration: InputDecoration(
                                            hintText: "Yurt Seç",
                                            hintStyle: TextStyle(
                                              color: Colors.grey,
                                              fontFamily: "MontserratMedium",
                                            ),
                                            border: InputBorder.none,
                                            suffixIcon: Icon(
                                              CupertinoIcons.chevron_down,
                                              color: Colors.black,
                                              size: 20,
                                            ),
                                          ),
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
                                          ),
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (controller.sehir.value != "Şehir Seç" &&
                                  controller.sub.value != "İdari Seç")
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: controller.toggleListedeYok,
                                        child: Container(
                                          height: 20,
                                          width: 20,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.all(
                                              Radius.circular(4),
                                            ),
                                            border: Border.all(
                                              color: Colors.grey,
                                            ),
                                          ),
                                          child: Obx(
                                            () => controller.listedeYok.value
                                                ? Icon(
                                                    Icons.check,
                                                    color: Colors.black,
                                                    size: 20,
                                                  )
                                                : SizedBox(),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        "Listede Yok",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (controller.listedeYok.value &&
                                  controller.sehir.value != "Şehir Seç" &&
                                  controller.sub.value != "İdari Seç")
                                Container(
                                  alignment: Alignment.center,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: TextField(
                                      cursorColor: Colors.black,
                                      controller: controller.yurtInput,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      keyboardType: TextInputType.text,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(50),
                                      ],
                                      decoration: InputDecoration(
                                        hintText: "Yurt Adı",
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                          fontFamily: "MontserratMedium",
                                        ),
                                        border: InputBorder.none,
                                        suffixIcon: Obx(
                                          () => controller.yurtInputText.value
                                                  .isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(
                                                    Icons.clear,
                                                    color: Colors.grey,
                                                  ),
                                                  onPressed: () {
                                                    controller.yurtInput
                                                        .clear();
                                                    controller.yurtInputText
                                                        .value = "";
                                                  },
                                                )
                                              : SizedBox(),
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "MontserratMedium",
                                      ),
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
            Obx(
              () => (controller.listedeYok.value &&
                          controller.yurtInputText.value.isNotEmpty) ||
                      (!controller.listedeYok.value &&
                          controller.yurt.value.isNotEmpty)
                  ? Padding(
                      padding: EdgeInsets.all(16),
                      child: GestureDetector(
                        onTap: controller.saveData,
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.all(
                              Radius.circular(12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            "Kaydet",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontFamily: "MontserratMedium",
                            ),
                          ),
                        ),
                      ),
                    )
                  : SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
