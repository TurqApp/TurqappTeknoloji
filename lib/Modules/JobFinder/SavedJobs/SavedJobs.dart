import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/Buttons/BackButtons.dart';
import 'package:turqappv2/Core/EmptyRow.dart';
import 'package:turqappv2/Modules/JobFinder/JobContent/JobContent.dart';
import 'package:turqappv2/Modules/JobFinder/SavedJobs/SavedJobController.dart';

class SavedJobs extends StatelessWidget {
  SavedJobs({super.key});
  final controller = Get.put(SavedJobsController());
  @override
  Widget build(BuildContext context) {
    controller.getStartData();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [BackButtons(text: "Kaydedilen İlanlar")],
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
