import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'job_selector_controller.dart';

part 'job_selector_content_part.dart';

class JobSelector extends StatefulWidget {
  const JobSelector({super.key});

  @override
  State<JobSelector> createState() => _JobSelectorState();
}

class _JobSelectorState extends State<JobSelector> {
  late final JobSelectorController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    final existingController = JobSelectorController.maybeFind();
    if (existingController != null) {
      controller = existingController;
      _ownsController = false;
    } else {
      controller = JobSelectorController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(JobSelectorController.maybeFind(), controller)) {
      Get.delete<JobSelectorController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [BackButtons(text: 'job_selector.title'.tr)],
                ),
                const SizedBox(height: 12),
                Text(
                  'job_selector.subtitle'.tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: "MontserratMedium",
                  ),
                ),
                const SizedBox(height: 12),
                _buildSearchField(),
                _buildJobList(),
                const SizedBox(height: 14),
                TurqAppButton(
                  text: 'common.save'.tr,
                  onTap: () {
                    controller.setData();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
