import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/info_message.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringSearch/tutoring_search_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_widget_builder.dart';
import 'package:turqappv2/Modules/Education/Tutoring/view_mode_controller.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: Get.back,
                    icon: const Icon(
                      CupertinoIcons.arrow_left,
                      color: Colors.black,
                    ),
                  ),
                  Expanded(
                    child: TurqSearchBar(
                      controller: controller.searchController,
                      hintText: "Ara",
                      onChanged: controller.updateSearchQuery,
                    ),
                  ),
                ],
              ),
            ),
            12.ph,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CupertinoActivityIndicator());
                  } else if (controller.searchResults.isEmpty) {
                    return const Center(
                      child: Text("Aramana uygun ilan bulunamadı"),
                    );
                  } else {
                    return SingleChildScrollView(
                      child: TutoringWidgetBuilder(
                        tutoringList: controller.searchResults,
                        users: controller.users,
                        isGridView: viewModeController.isGridView.value,
                        infoMessage: const Infomessage(
                          infoMessage: "Eşleşen özel ders bulunmuyor!",
                        ),
                      ),
                    );
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
