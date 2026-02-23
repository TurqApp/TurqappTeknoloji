import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Education/optical_form_model.dart';
import 'package:turqappv2/Modules/Education/AnswerKey/OpticalPreview/optical_preview_controller.dart';

class OpticalPreview extends StatelessWidget {
  final OpticalFormModel model;
  final Function? update;
  final Function gecersizSay;

  const OpticalPreview({
    super.key,
    required this.model,
    this.update,
    required this.gecersizSay,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      OpticalPreviewController(model, update, gecersizSay),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Obx(
              () => controller.selection.value == 1
                  ? Column(
                      children: [
                        Container(
                          height: 70,
                          color: Colors.white,
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              controller.fullName.text,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 25,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: model.cevaplar.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          left: 10,
                                          right: 20,
                                          top: index == 0 ? 10 : 0,
                                        ),
                                        child: Container(
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: index % 2 == 0
                                                ? Colors.pink.withValues(alpha: 
                                                    0.05,
                                                  )
                                                : Colors.pink.withValues(alpha: 
                                                    0.2,
                                                  ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                width: 35,
                                                height: 35,
                                                child: Center(
                                                  child: Text(
                                                    "${index + 1}.",
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 20,
                                                      fontFamily:
                                                          "MontserratBold",
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              for (var item in model.max == 5
                                                  ? [
                                                      "A",
                                                      "B",
                                                      "C",
                                                      "D",
                                                      "E",
                                                    ]
                                                  : ["A", "B", "C", "D"])
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 4.0,
                                                  ),
                                                  child: GestureDetector(
                                                    onTap: () =>
                                                        controller.toggleAnswer(
                                                      index,
                                                      item,
                                                    ),
                                                    child: Obx(
                                                      () => Container(
                                                        width: 40,
                                                        height: 40,
                                                        alignment:
                                                            Alignment.center,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: controller
                                                                          .cevaplar[
                                                                      index] ==
                                                                  item
                                                              ? Colors.black
                                                              : Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            50,
                                                          ),
                                                          border: Border.all(
                                                            color: Colors.black,
                                                            width: 1.5,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          item,
                                                          style: TextStyle(
                                                            color: controller
                                                                            .cevaplar[
                                                                        index] ==
                                                                    item
                                                                ? Colors.white
                                                                : Colors.black,
                                                            fontSize: 20,
                                                            fontFamily:
                                                                "MontserratBold",
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.all(20),
                                  child: GestureDetector(
                                    onTap: () => controller.handleFinishTest(
                                      context,
                                    ),
                                    child: Container(
                                      height: 45,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.indigo,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        "Test'i Bitir",
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
                        ),
                      ],
                    )
                  : controller.selection.value == 0
                      ? Container(
                          color: Colors.white,
                          child: ListView(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(25),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 20),
                                    Text(
                                      "Test Başlamıştır!",
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontSize: 25,
                                        fontFamily: "MontserratBold",
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      "Test'e gösterdiğiniz özen ve çabanın, başarıya giden yolu açacağına inanıyoruz. Bol şans ve başarılar dileriz!",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontFamily: "MontserratMedium",
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Divider(color: Colors.grey),
                                    SizedBox(height: 12),
                                    Text(
                                      "Test Kuralları",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontFamily: "MontserratBold",
                                      ),
                                    ),
                                    SizedBox(height: 15),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: Text(
                                            "1-)",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontFamily: "MontserratBold",
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "Lütfen telefonunuzun internet bağlantısını kapatınız. Sınavınız tamamlandığında, internetinizi yeniden açarak cevaplarınızı gönderebileceğiniz ekranı görüntüleyebilirsiniz.",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontFamily: "MontserratMedium",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 15),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: Text(
                                            "2-)",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontFamily: "MontserratBold",
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "Sınavdan çıkmak isterseniz, tüm cevaplarınız geçersiz sayılacaktır ve puanınız kaydedilmeyecektir. Bu işlemi onaylamadan önce dikkatlice düşünmeniz önerilir.",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontFamily: "MontserratMedium",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 15),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: Text(
                                            "3-)",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontFamily: "MontserratBold",
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            "Uygulamayı arka plana aldığınızda sınavınız geçersiz sayılacaktır. Bu yüzden uygulamayı arka plana almamaya özen gösteriniz.",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontFamily: "MontserratMedium",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 15),
                                    Container(
                                      height: 50,
                                      alignment: Alignment.centerLeft,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 15,
                                        ),
                                        child: TextField(
                                          controller: controller.fullName,
                                          maxLines: 1,
                                          keyboardType: TextInputType.text,
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            hintText: "Ad Soyad",
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
                                    SizedBox(height: 15),
                                    Container(
                                      height: 50,
                                      alignment: Alignment.centerLeft,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(12),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 15,
                                        ),
                                        child: TextField(
                                          controller: controller.ogrenciNo,
                                          maxLines: 1,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            hintText: "Öğrenci Numaranız",
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
                                    SizedBox(height: 15),
                                    Obx(
                                      () {
                                        if (!controller.isConnected.value) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Lütfen internet bağlantınızı kapatın.",
                                                  style: TextStyle(
                                                    fontFamily:
                                                        "MontserratMedium",
                                                  ),
                                                ),
                                                backgroundColor: Colors.red,
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          });
                                        } else if (controller
                                                .fullName.text.length <
                                            6) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Ad ve soyad en az 6 karakter olmalı.",
                                                  style: TextStyle(
                                                    fontFamily:
                                                        "MontserratMedium",
                                                  ),
                                                ),
                                                backgroundColor: Colors.red,
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          });
                                        } else if (controller
                                            .ogrenciNo.text.isEmpty) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Öğrenci numarası boş olamaz.",
                                                  style: TextStyle(
                                                    fontFamily:
                                                        "MontserratMedium",
                                                  ),
                                                ),
                                                backgroundColor: Colors.red,
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          });
                                        }
                                        return !controller.isConnected.value &&
                                                controller
                                                        .fullName.text.length >=
                                                    6 &&
                                                controller
                                                    .ogrenciNo.text.isNotEmpty
                                            ? GestureDetector(
                                                onTap: () =>
                                                    controller.startTest(),
                                                child: Container(
                                                  height: 45,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: Colors.indigo,
                                                    borderRadius:
                                                        BorderRadius.all(
                                                      Radius.circular(12),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    "Test'e Başla",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontFamily:
                                                          "MontserratMedium",
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : SizedBox();
                                      },
                                    ),
                                    SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ],
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
