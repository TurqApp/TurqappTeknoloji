import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Core/Buttons/TurqAppButton.dart';
import 'package:turqappv2/Modules/Profile/EditorEmail/EditorEmailController.dart';

class EditorEmail extends StatelessWidget {
  EditorEmail({super.key});
  final controller = Get.put(EditorEmailController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Row(
                  children: [BackButtons(text: "Email Adresi")],
                ),
                SizedBox(
                  height: 12,
                ),
                Container(
                  height: 50,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: TextField(
                      controller: controller.emailController,
                      decoration: InputDecoration(
                        hintText: "Email adresini değiştir",
                        hintStyle: TextStyle(
                            color: Colors.grey, fontFamily: "MontserratMedium"),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium"),
                    ),
                  ),
                ),
                SizedBox(
                  height: 12,
                ),
                Container(
                  height: 50,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: TextField(
                      controller: controller.passwordController,
                      decoration: InputDecoration(
                        hintText: "Mevcut Şifreniz",
                        hintStyle: TextStyle(
                            color: Colors.grey, fontFamily: "MontserratMedium"),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium"),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 12),
                  child: Text(
                    "Email adresinizi devamlı değiştirmeniz durumunda, hesabınız askıya alınacaktır.",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratMedium"),
                  ),
                ),
                TurqAppButton(onTap: () {
                  controller.setData();
                })
              ],
            ),
          ),
        ),
      ),
    );
  }
}
