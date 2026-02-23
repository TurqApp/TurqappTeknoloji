import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Core/interests_list.dart';
import 'package:turqappv2/Modules/Profile/Interests/interest_controller.dart';

class Interests extends StatelessWidget {
  Interests({super.key});
  final controller = Get.put(InterestsController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "İlgi Alanları"),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: interestList.length,
                        itemBuilder: (context, index) {
                          return Obx(() {
                            return GestureDetector(
                              onTap: () {
                                controller.select(interestList[index]);
                              },
                              child: Container(
                                color: Colors.transparent,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            interestList[index],
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                                fontFamily: controller.selecteds
                                                        .contains(
                                                            interestList[index])
                                                    ? "MontserratBold"
                                                    : "Montserrat"),
                                          ),
                                        ),
                                        Container(
                                          width: 30,
                                          height: 30,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                              border: Border.all(
                                                  color: Colors.grey)),
                                          child: Container(
                                            width: 20,
                                            height: 20,
                                            decoration: BoxDecoration(
                                              color: controller.selecteds
                                                      .contains(
                                                          interestList[index])
                                                  ? Colors.black
                                                  : Colors.transparent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    Divider(
                                      color: Colors.grey.withAlpha(10),
                                    )
                                  ],
                                ),
                              ),
                            );
                          });
                        },
                      ),
                      TurqAppButton(onTap: () {
                        controller.setData();
                      }),
                      SizedBox(
                        height: 12,
                      ),
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
