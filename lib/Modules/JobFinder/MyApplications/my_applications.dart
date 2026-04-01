import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/job_application_model.dart';
import 'my_applications_controller.dart';

part 'my_applications_card_part.dart';

class MyApplications extends StatefulWidget {
  const MyApplications({super.key});

  @override
  State<MyApplications> createState() => _MyApplicationsState();
}

class _MyApplicationsState extends State<MyApplications> {
  late final String _controllerTag;
  late final MyApplicationsController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _controllerTag = 'my_applications_${identityHashCode(this)}';
    _ownsController =
        maybeFindMyApplicationsController(tag: _controllerTag) == null;
    controller = ensureMyApplicationsController(tag: _controllerTag);
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(
          maybeFindMyApplicationsController(tag: _controllerTag),
          controller,
        )) {
      Get.delete<MyApplicationsController>(tag: _controllerTag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const AppBackButton(),
        title: AppPageTitle('pasaj.job_finder.my_applications'.tr),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CupertinoActivityIndicator());
        }

        return RefreshIndicator(
          onRefresh: controller.loadApplications,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 24),
            children: [
              if (controller.applications.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: EmptyRow(text: "pasaj.job_finder.no_applications".tr),
                )
              else
                ...controller.applications.map(_applicationCard),
            ],
          ),
        );
      }),
    );
  }
}
