import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Core/infoMessage.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringSearch/TutoringSearchController.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringWidgetBuilder.dart';
import 'package:turqappv2/Modules/Education/Tutoring/ViewModeController.dart.dart';
import 'package:turqappv2/Themes/AppIcons.dart';
import 'package:turqappv2/Utils/EmptyPadding.dart';

class TutoringSearch extends StatelessWidget {
  const TutoringSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final TutoringSearchController controller = Get.put(
      TutoringSearchController(),
    );
    final ViewModeController viewModeController =
        Get.find<ViewModeController>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Özel Ders Ara"),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 15),
              height: 50,
              child: CupertinoTextField(
                cursorColor: Colors.black,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade200,
                ),
                placeholder: "Ara",
                onChanged: controller.updateSearchQuery,
                prefix: Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(AppIcons.search, color: Colors.black45),
                ),
                autofocus: true,
                textInputAction: TextInputAction.search,
              ),
            ),
            12.ph,
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Center(child: CupertinoActivityIndicator());
                  } else if (controller.searchResults.isEmpty) {
                    return Center(child: Text("Eşleşen özel ders bulunmuyor."));
                  } else {
                    return Obx(() {
                      return SingleChildScrollView(
                        child: TutoringWidgetBuilder(
                          tutoringList: controller.searchResults,
                          users: controller.users,
                          isGridView: viewModeController.isGridView.value,
                          infoMessage: Infomessage(
                            infoMessage: "Eşleşen özel ders bulunmuyor!",
                          ),
                        ),
                      );
                    });
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
