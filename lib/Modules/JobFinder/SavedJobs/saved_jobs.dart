import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/job_content.dart';
import 'package:turqappv2/Modules/JobFinder/SavedJobs/saved_job_controller.dart';

class SavedJobs extends StatelessWidget {
  SavedJobs({super.key});
  final controller = Get.put(SavedJobsController());
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
                children: [BackButtons(text: "Kaydedilenler")],
              ),
            ),
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CupertinoActivityIndicator(color: Colors.black),
                );
              }

              if (controller.list.isEmpty) {
                return EmptyRow(text: "Kaydedilen ilan yok.");
              }

              return Expanded(
                child: ListView.builder(
                  itemCount: controller.list.length,
                  itemBuilder: (context, index) {
                    return JobContent(
                      model: controller.list[index],
                      isGrid: false,
                    );
                  },
                ),
              );
            })
          ],
        ),
      ),
    );
  }
}
