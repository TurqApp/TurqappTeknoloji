import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Helpers/custom_nickname_formatter.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'package:turqappv2/Modules/Profile/EditorNickname/editor_nickname_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class EditorNickname extends StatelessWidget {
  EditorNickname({super.key});
  final controller = Get.put(EditorNicknameController());
  final userService = CurrentUserService.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Kullanıcı Adı"),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Obx(() {
                      final current = userService.currentUserRx.value;
                      final rozet = current?.rozet ?? '';
                      final nickname = current?.nickname ?? '';
                      return Column(
                        children: [
                          if (rozet == "")
                            Container(
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
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller:
                                            controller.nicknameController,
                                        autofocus: true,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(20),
                                          CustomNicknameFormatter(),
                                        ],
                                        decoration: InputDecoration(
                                          hintText: "Kullanıcı Adı Oluştur",
                                          hintStyle: TextStyle(
                                              color: Colors.grey,
                                              fontFamily: "MontserratMedium"),
                                          border: InputBorder.none,
                                        ),
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium"),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (rozet == "")
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Obx(() {
                                final checking = controller.isChecking.value;
                                final available = controller.isAvailable.value;
                                final text = controller.statusText.value;
                                Color color;
                                if (checking) {
                                  color = Colors.grey;
                                } else if (available == true) {
                                  color = Colors.green;
                                } else if (available == false) {
                                  color = Colors.red;
                                } else {
                                  color = Colors.grey;
                                }
                                return Row(
                                  children: [
                                    if (checking)
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CupertinoActivityIndicator(
                                            radius: 7),
                                      ),
                                    if (checking) SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        text,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 13,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            )
                          else
                            Container(
                              height: 50,
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.03),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(12)),
                              ),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                  child: Text(
                                    nickname,
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 15,
                                        fontFamily: "MontserratMedium"),
                                  )),
                            ),
                          if (rozet != "")
                            Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  Text(
                                    "Onaylı kullanıcılar, kullanıcı adını değiştiremez",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontFamily: "MontserratMedium"),
                                  ),
                                ],
                              ),
                            )
                          else
                            Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Gerçek kişileri taklit eden kullanıcı adları, topluluğumuzu korumak adına Turqapp tarafından değiştirilebilir.",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontFamily: "Montserrat"),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Türkçe karakterler otomatik dönüştürülür. (ç→c, ğ→g, ı→i, ö→o, ş→s, ü→u)",
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                        fontFamily: "Montserrat"),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                            height: 12,
                          ),
                          Obx(() {
                            final canSave = controller.canSave;
                            return TurqAppButton(
                              onTap: () {
                                if (canSave) controller.setData();
                              },
                              bgColor: canSave
                                  ? Colors.black
                                  : Colors.black.withValues(alpha: 0.3),
                            );
                          })
                        ],
                      );
                    })),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
