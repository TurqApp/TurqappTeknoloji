import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Modules/Education/Tests/MyTestResults/my_test_results_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/TestPastResultContent/test_past_result_content.dart';

class MyTestResults extends StatefulWidget {
  const MyTestResults({super.key});

  @override
  State<MyTestResults> createState() => _MyTestResultsState();
}

class _MyTestResultsState extends State<MyTestResults> {
  late final String _controllerTag;
  late final bool _ownsController;
  late final MyTestResultsController controller;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'tests_results_${identityHashCode(this)}';
    final existing = maybeFindMyTestResultsController(tag: _controllerTag);
    _ownsController = existing == null;
    controller = existing ?? ensureMyTestResultsController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController) {
      final registeredController = maybeFindMyTestResultsController(
        tag: _controllerTag,
      );
      if (identical(registeredController, controller)) {
        Get.delete<MyTestResultsController>(tag: _controllerTag, force: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPage();
  }

  Widget _buildPage() {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'tests.results_title'.tr),
            Expanded(
              child: RefreshIndicator(
                color: Colors.white,
                backgroundColor: Colors.black,
                onRefresh: controller.findAndGetTestler,
                child: Obx(() => _buildContent()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (controller.isLoading.value) {
      return const AppStateView.loading(title: '');
    }

    if (controller.list.isEmpty) {
      return AppStateView.empty(
        title: 'tests.my_results_empty'.tr,
        icon: Icons.info_outline,
      );
    }

    return ListView.builder(
      itemCount: controller.list.length,
      itemBuilder: (context, index) {
        return TestPastResultContent(
          index: index,
          model: controller.list[index],
        );
      },
    );
  }
}
