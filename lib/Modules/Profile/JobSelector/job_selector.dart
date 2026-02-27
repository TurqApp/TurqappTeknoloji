import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_button.dart';
import 'job_selector_controller.dart';

class JobSelector extends StatelessWidget {
  JobSelector({super.key});
  final controller = Get.put(JobSelectorController());

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
                  children: [BackButtons(text: "Meslek & Kategori")],
                ),
                const SizedBox(height: 12),
                Text(
                  "Kategorin, profilinin keşfedilmesini kolaylaştırır.",
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: "MontserratMedium",
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      onChanged: controller.filterJobs,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Colors.grey),
                        hintText: "Ara",
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontFamily: "Montserrat",
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "Montserrat",
                      ),
                    ),
                  ),
                ),
                Obx(() {
                  final selectedJob = controller.job.value;
                  final jobs = controller.filteredJobs;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: jobs.length,
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      final isSelected = job.trim() == selectedJob.trim();
                      return Padding(
                        padding: EdgeInsets.only(top: index == 0 ? 14 : 8),
                        child: GestureDetector(
                          onTap: () {
                            controller.selectJob(job);
                          },
                          child: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.white,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(12)),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey.withValues(alpha: 0.20),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    job,
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontFamily: isSelected
                                          ? "MontserratBold"
                                          : "Montserrat",
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected ? Colors.black : Colors.white,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(15),
                                    ),
                                    border: Border.all(
                                      color:
                                          isSelected ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          CupertinoIcons.checkmark,
                                          color: Colors.white,
                                          size: 12,
                                        )
                                      : const SizedBox(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
                const SizedBox(height: 14),
                TurqAppButton(
                  text: "Kaydet",
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
