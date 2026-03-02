import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/turq_app_toggle.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv.dart';
import 'career_profile_controller.dart';

class CareerProfile extends StatelessWidget {
  CareerProfile({super.key});
  final controller = Get.put(CareerProfileController());

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CupertinoActivityIndicator());
      }

      if (!controller.cvVar.value) {
        return _noCvView();
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Finding job toggle
            GestureDetector(
              onTap: () => controller.toggleFindingJob(),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "İş Arıyorum",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                    Obx(() =>
                        TurqAppToggle(isOn: controller.isFindingJob.value)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Name & About
            if (controller.fullName.value.isNotEmpty)
              Text(
                controller.fullName.value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
              ),

            if (controller.about.value.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                controller.about.value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: "Montserrat",
                ),
              ),
            ],

            // Experiences
            if (controller.experiences.isNotEmpty) ...[
              const SizedBox(height: 20),
              _sectionTitle("İş Deneyimi"),
              const SizedBox(height: 8),
              ...controller.experiences.map((exp) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exp.position,
                              style: const TextStyle(
                                  fontFamily: "MontserratBold",
                                  fontSize: 14,
                                  color: Colors.black)),
                          const SizedBox(height: 4),
                          Text(exp.company,
                              style: const TextStyle(
                                  fontFamily: "MontserratMedium",
                                  fontSize: 13,
                                  color: Colors.pinkAccent)),
                          if (exp.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(exp.description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontFamily: "Montserrat",
                                    fontSize: 12,
                                    color: Colors.grey.shade700)),
                          ],
                          Text("${exp.year1} - ${exp.year2}",
                              style: const TextStyle(
                                  fontFamily: "MontserratMedium",
                                  fontSize: 13,
                                  color: Colors.blueAccent)),
                        ],
                      ),
                    ),
                  )),
            ],

            // Education
            if (controller.schools.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle("Eğitim"),
              const SizedBox(height: 8),
              ...controller.schools.map((school) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(school.school,
                              style: const TextStyle(
                                  fontFamily: "MontserratBold",
                                  fontSize: 14,
                                  color: Colors.black)),
                          const SizedBox(height: 4),
                          Text("${school.branch} - ${school.lastYear}",
                              style: const TextStyle(
                                  fontFamily: "MontserratMedium",
                                  fontSize: 13,
                                  color: Colors.pinkAccent)),
                        ],
                      ),
                    ),
                  )),
            ],

            // Languages
            if (controller.languages.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle("Diller"),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.languages.map((lang) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(lang.languege,
                            style: const TextStyle(
                                fontFamily: "MontserratMedium",
                                fontSize: 13,
                                color: Colors.black)),
                        const SizedBox(width: 6),
                        ...List.generate(
                            5,
                            (i) => Icon(
                                  i < lang.level
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: i < lang.level
                                      ? Colors.amber
                                      : Colors.grey,
                                  size: 14,
                                )),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            // Skills
            if (controller.skills.isNotEmpty) ...[
              const SizedBox(height: 12),
              _sectionTitle("Beceriler"),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.skills.map((skill) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(skill,
                        style: const TextStyle(
                            fontFamily: "MontserratMedium",
                            fontSize: 13,
                            color: Colors.blueAccent)),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),

            // Edit CV button
            GestureDetector(
              onTap: () async {
                await Get.to(() => Cv());
                controller.loadCvData();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  "CV Düzenle",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: "MontserratBold",
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      );
    });
  }

  Widget _noCvView() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(CupertinoIcons.doc_text, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          const Text(
            "Henüz bir CV oluşturmadınız",
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: "MontserratMedium",
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "CV oluşturarak iş başvurularınızı hızlandırın",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontFamily: "Montserrat",
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () async {
              await Get.to(() => Cv());
              Get.find<CareerProfileController>().loadCvData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Text(
                "CV Oluştur",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontFamily: "MontserratBold",
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: "MontserratBold",
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
      ],
    );
  }
}
