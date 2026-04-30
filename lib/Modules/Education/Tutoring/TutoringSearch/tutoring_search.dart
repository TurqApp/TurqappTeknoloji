import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/info_message.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Core/Widgets/search_reset_on_page_return_scope.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Modules/Education/Tutoring/TutoringSearch/tutoring_search_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_widget_builder.dart';
import 'package:turqappv2/Modules/Education/Tutoring/view_mode_controller.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class TutoringSearch extends StatefulWidget {
  const TutoringSearch({super.key});

  @override
  State<TutoringSearch> createState() => _TutoringSearchState();
}

class _TutoringSearchState extends State<TutoringSearch> {
  late final TutoringSearchController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = maybeFindTutoringSearchController() == null;
    controller = ensureTutoringSearchController();
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(maybeFindTutoringSearchController(), controller)) {
      Get.delete<TutoringSearchController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ViewModeController viewModeController =
        ensureViewModeController(permanent: true);

    return SearchResetOnPageReturnScope(
      onReset: controller.resetSearch,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                child: Row(
                  children: [
                    const AppBackButton(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TurqSearchBar(
                        controller: controller.searchController,
                        hintText: 'common.search'.tr,
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
                    if (!viewModeController.isReady.value) {
                      return const AppStateView.loading(title: '');
                    }
                    if (controller.isLoading.value) {
                      return const AppStateView.loading(title: '');
                    } else if (controller.searchResults.isEmpty) {
                      return AppStateView.empty(
                        title: 'tutoring.search_empty'.tr,
                      );
                    } else {
                      return SingleChildScrollView(
                        child: TutoringWidgetBuilder(
                          tutoringList: controller.searchResults,
                          isGridView: viewModeController.isGridView.value,
                          infoMessage: Infomessage(
                            infoMessage: 'tutoring.search_empty_info'.tr,
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
      ),
    );
  }
}
