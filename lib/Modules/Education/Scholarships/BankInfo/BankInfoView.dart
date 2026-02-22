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
import 'package:turqappv2/Core/TextStyles.dart';
import 'package:turqappv2/Modules/Education/Scholarships/BankInfo/BankInfoController.dart';

class BankInfoView extends StatelessWidget {
  BankInfoView({super.key});

  final BankInfoController controller = Get.put(BankInfoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: BackButtons(text: "Banka Bilgileri"),
                  ),
                  PullDownButton(
                    itemBuilder: (context) => [
                      PullDownMenuItem(
                        title: 'Banka Bilgilerimi Sıfırla',
                        icon: CupertinoIcons.restart,
                        onTap: () {
                          noYesAlert(
                            title: "Emin misiniz?",
                            message:
                                "Banka bilgileriniz sıfırlanacak. Bu işlem geri alınamaz.",
                            cancelText: "İptal",
                            yesText: "Sıfırla",
                            yesButtonColor: CupertinoColors.destructiveRed,
                            onYesPressed: () async {
                              controller.selectedBank.value = "Banka Seç";
                              controller.kolayAdres.value = "E-Posta";
                              controller.iban.clear();
                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(FirebaseAuth.instance.currentUser?.uid)
                                  .update({
                                "iban": "",
                                "bank": "",
                                "kolayAdresSelection": "",
                              });
                              AppSnackbar(
                                "Başarılı",
                                "Banka Bilgileriniz sıfırlandı.",
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
              Obx(
                () => controller.isLoading.value
                    ? Center(child: CupertinoActivityIndicator())
                    : Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Kolay Adres (FAST)",
                                  style: TextStyles.textFieldTitle,
                                ),
                                GestureDetector(
                                  onTap: () => controller
                                      .showKolayAdresBottomSheet(context),
                                  child: Container(
                                    height: 50,
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(20),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8)),
                                    ),
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      child: Obx(
                                        () => Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              controller.kolayAdres.value,
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                            Icon(
                                              CupertinoIcons.chevron_down,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  "Banka",
                                  style: TextStyles.textFieldTitle,
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      controller.showBankBottomSheet(context),
                                  child: Container(
                                    height: 50,
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(20),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(8)),
                                    ),
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      child: Obx(
                                        () => Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              controller.selectedBank.value,
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 15,
                                                fontFamily: "MontserratMedium",
                                              ),
                                            ),
                                            Icon(
                                              CupertinoIcons.chevron_down,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  controller.kolayAdres.value,
                                  style: TextStyles.textFieldTitle,
                                ),
                                Container(
                                  alignment: Alignment.centerLeft,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withAlpha(20),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(8)),
                                  ),
                                  child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      children: [
                                        Obx(
                                          () => controller.kolayAdres.value ==
                                                  "IBAN"
                                              ? Row(
                                                  children: [
                                                    Text(
                                                      "TR",
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 15,
                                                        fontFamily:
                                                            "MontserratMedium",
                                                      ),
                                                    ),
                                                    SizedBox(width: 4),
                                                  ],
                                                )
                                              : controller.kolayAdres.value ==
                                                      "Telefon"
                                                  ? Row(
                                                      children: [
                                                        Text(
                                                          "(+90) ",
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontSize: 15,
                                                            fontFamily:
                                                                "MontserratMedium",
                                                          ),
                                                        ),
                                                        SizedBox(width: 4),
                                                      ],
                                                    )
                                                  : SizedBox.shrink(),
                                        ),
                                        Expanded(
                                          child: TextField(
                                            controller: controller.iban,
                                            inputFormatters: controller
                                                        .kolayAdres.value ==
                                                    "IBAN"
                                                ? [
                                                    LengthLimitingTextInputFormatter(
                                                        16),
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ]
                                                : controller.kolayAdres.value ==
                                                        "Telefon"
                                                    ? [
                                                        LengthLimitingTextInputFormatter(
                                                            10),
                                                        FilteringTextInputFormatter
                                                            .digitsOnly,
                                                      ]
                                                    : controller.kolayAdres
                                                                .value ==
                                                            "E-Posta"
                                                        ? [
                                                            LengthLimitingTextInputFormatter(
                                                                50),
                                                          ]
                                                        : [],
                                            keyboardType: controller
                                                            .kolayAdres.value ==
                                                        "IBAN" ||
                                                    controller
                                                            .kolayAdres.value ==
                                                        "Telefon"
                                                ? TextInputType.number
                                                : TextInputType.emailAddress,
                                            decoration: InputDecoration(
                                              hintText:
                                                  controller.kolayAdres.value,
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
                                            onChanged: (val) =>
                                                controller.iban.text = val,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: controller.pasteFromClipboard,
                                          child: Icon(
                                            CupertinoIcons.doc_on_doc,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(15),
                            child: GestureDetector(
                              onTap: controller.saveData,
                              child: Container(
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Color(controller.color.value),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(12)),
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
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
