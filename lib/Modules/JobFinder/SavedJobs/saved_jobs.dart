import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/job_content.dart';
import 'package:turqappv2/Modules/JobFinder/SavedJobs/saved_job_controller.dart';

class SavedJobs extends StatefulWidget {
  const SavedJobs({super.key});

  @override
  State<SavedJobs> createState() => _SavedJobsState();
}

class _SavedJobsState extends State<SavedJobs> {
  late final String _controllerTag;
  late final SavedJobsController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'saved_jobs_${identityHashCode(this)}';
    _ownsController = maybeFindSavedJobsController(tag: _controllerTag) == null;
    controller = ensureSavedJobsController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindSavedJobsController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<SavedJobsController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [BackButtons(text: "pasaj.job_finder.saved_jobs".tr)],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const AppStateView.loading(title: '');
                }

                if (controller.list.isEmpty) {
                  return AppStateView.empty(
                    title: "pasaj.job_finder.no_saved_jobs".tr,
                  );
                }

                return ListView.builder(
                  itemCount: controller.list.length,
                  itemBuilder: (context, index) {
                    return JobContent(
                      model: controller.list[index],
                      isGrid: false,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
