import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/turq_app_toggle.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv.dart';
import 'career_profile_controller.dart';

class CareerProfile extends StatefulWidget {
  const CareerProfile({super.key});

  @override
  State<CareerProfile> createState() => _CareerProfileState();
}

class _CareerProfileState extends State<CareerProfile> {
  late final CareerProfileController controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<CareerProfileController>()) {
      controller = Get.find<CareerProfileController>();
      _ownsController = false;
    } else {
      controller = Get.put(CareerProfileController());
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        Get.isRegistered<CareerProfileController>() &&
        identical(Get.find<CareerProfileController>(), controller)) {
      Get.delete<CareerProfileController>();
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
        title: AppPageTitle('pasaj.job_finder.career_profile'.tr),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          if (controller.isLoading.value && !controller.cvVar.value) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (!controller.cvVar.value) {
            return _noCvView();
          }

          return RefreshIndicator(
            onRefresh: () => controller.loadCvData(forceRefresh: true),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F6FB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x14000000)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: controller.photoUrl.value.isEmpty
                                  ? Colors.black
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              image: controller.photoUrl.value.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        controller.photoUrl.value,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: controller.photoUrl.value.isEmpty
                                ? const Icon(
                                    CupertinoIcons.person_crop_rectangle,
                                    color: Colors.white,
                                    size: 24,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  controller.fullName.value.isNotEmpty
                                      ? controller.fullName.value
                                      : 'pasaj.job_finder.career_profile'.tr,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  controller.experiences.isNotEmpty
                                      ? controller.experiences.first.position
                                      : controller.schools.isNotEmpty
                                          ? controller.schools.first.branch
                                          : 'pasaj.job_finder.professional_profile'
                                              .tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                    fontFamily: 'MontserratMedium',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (controller.about.value.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Text(
                          controller.about.value,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            height: 1.45,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'pasaj.job_finder.looking_for_job'.tr,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: 'MontserratBold',
                                ),
                              ),
                            ),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: controller.toggleFindingJob,
                              child: TurqAppToggle(
                                isOn: controller.isFindingJob.value,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.experiences.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'pasaj.job_finder.experience'.tr,
                    children: controller.experiences
                        .map(
                          (exp) => _infoTile(
                            title: exp.position,
                            subtitle: exp.company,
                            trailing: '${exp.year1} - ${exp.year2}',
                            detail: exp.description,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                if (controller.schools.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _sectionCard(
                    title: 'pasaj.job_finder.education'.tr,
                    children: controller.schools
                        .map(
                          (school) => _infoTile(
                            title: school.school,
                            subtitle: school.branch,
                            trailing: school.lastYear,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                if (controller.languages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _surface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'pasaj.job_finder.languages'.tr,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: controller.languages.map((lang) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F6FB),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    lang.languege,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 13,
                                      fontFamily: 'MontserratMedium',
                                    ),
                                  ),
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
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ],
                if (controller.skills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _surface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'pasaj.job_finder.skills'.tr,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: controller.skills
                              .map(
                                (skill) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F6FB),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    skill,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 13,
                                      fontFamily: 'MontserratMedium',
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Get.to(() => Cv());
                      await controller.loadCvData();
                    },
                    child: Text('pasaj.job_finder.edit_cv'.tr),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _noCvView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.doc_text,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'pasaj.job_finder.no_cv_title'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'MontserratBold',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'pasaj.job_finder.no_cv_body'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontFamily: 'MontserratMedium',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () async {
                  await Get.to(() => Cv());
                  await Get.find<CareerProfileController>().loadCvData();
                },
                child: Text('pasaj.job_finder.create_cv'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return _surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'MontserratBold',
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile({
    required String title,
    required String subtitle,
    required String trailing,
    String detail = '',
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
              if (detail.isNotEmpty || trailing.isNotEmpty)
                Container(
                  width: 1,
                  height: 72,
                  color: const Color(0x22000000),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FB),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                fontFamily: 'MontserratMedium',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        trailing,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ],
                  ),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      detail,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        height: 1.4,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _surface({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: child,
    );
  }
}
