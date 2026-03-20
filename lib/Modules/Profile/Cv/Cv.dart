import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv_controller.dart';

class Cv extends StatelessWidget {
  final CvController controller = Get.put(CvController());

  Cv({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
        ),
        title: Text(
          'cv.title'.tr,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: "MontserratBold",
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('cv.personal_info'.tr),
                const SizedBox(height: 12),
                step1(),
                const SizedBox(height: 24),
                _sectionTitle('cv.education_info'.tr),
                const SizedBox(height: 12),
                step2(),
                const SizedBox(height: 24),
                _sectionTitle('cv.other_info'.tr),
                const SizedBox(height: 12),
                step3(),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    if (controller.isSaving.value) return;
                    if (controller.firstName.text.trim().isEmpty) {
                      AppSnackbar(
                          'cv.missing_field'.tr, 'cv.missing_first_name'.tr);
                    } else if (controller.lastName.text.trim().isEmpty) {
                      AppSnackbar(
                          'cv.missing_field'.tr, 'cv.missing_last_name'.tr);
                    } else if (controller.mail.text.trim().isEmpty) {
                      AppSnackbar(
                          'cv.missing_field'.tr, 'cv.missing_email'.tr);
                    } else if (!controller
                        .validateEmail(controller.mail.text.trim())) {
                      AppSnackbar(
                          'cv.invalid_format'.tr, 'cv.invalid_email'.tr);
                    } else if (controller.phoneNumber.text.trim().isEmpty) {
                      AppSnackbar(
                          'cv.missing_field'.tr, 'cv.missing_phone'.tr);
                    } else if (!controller
                        .validatePhone(controller.phoneNumber.text)) {
                      AppSnackbar(
                          'cv.invalid_format'.tr, 'cv.invalid_phone'.tr);
                    } else if (controller.onYazi.text.trim().isEmpty) {
                      AppSnackbar(
                          'cv.missing_field'.tr, 'cv.missing_about'.tr);
                    } else if (controller.okullar.isEmpty) {
                      AppSnackbar(
                          'cv.missing_field'.tr, 'cv.missing_school'.tr);
                    } else {
                      controller.setData();
                    }
                  },
                  child: Container(
                    height: 48,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: controller.isSaving.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'cv.save'.tr,
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
        }),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontFamily: "MontserratBold",
      ),
    );
  }

  Widget _buildAddRow({
    required String text,
    required VoidCallback onTap,
    EdgeInsetsGeometry? margin,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.add,
              color: Colors.black,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontFamily: "MontserratMedium",
                fontSize: 13,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget step1() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x14000000)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                final photoUrl = controller.photoUrl.value.trim();
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => controller.pickCvPhoto(Get.context!),
                  child: Stack(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0x14000000)),
                          image: photoUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(photoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: photoUrl.isEmpty
                            ? const Icon(
                                CupertinoIcons.person_crop_circle_badge_plus,
                                color: Colors.black54,
                                size: 34,
                              )
                            : null,
                      ),
                      if (controller.isUploadingPhoto.value)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'cv.profile_title'.tr,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'cv.profile_body'.tr,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        height: 1.4,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextField(
                    controller: controller.firstName,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-zÇçĞğİıÖöŞşÜü\s]'),
                      ),
                    ],
                    decoration: InputDecoration(
                      hintText: 'cv.first_name_hint'.tr,
                      hintStyle: TextStyle(
                          color: Colors.grey, fontFamily: "MontserratMedium"),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratMedium"),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextField(
                    controller: controller.lastName,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-zÇçĞğİıÖöŞşÜü\s]'),
                      ),
                    ],
                    decoration: InputDecoration(
                      hintText: 'cv.last_name_hint'.tr,
                      hintStyle: TextStyle(
                          color: Colors.grey, fontFamily: "MontserratMedium"),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratMedium"),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        Container(
          height: 50,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              controller: controller.mail,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'cv.email_hint'.tr,
                hintStyle: TextStyle(
                    color: Colors.grey, fontFamily: "MontserratMedium"),
                border: InputBorder.none,
              ),
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium"),
            ),
          ),
        ),
        SizedBox(height: 15),
        Container(
          height: 50,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              controller: controller.phoneNumber,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              decoration: InputDecoration(
                hintText: 'cv.phone_hint'.tr,
                hintStyle: TextStyle(
                    color: Colors.grey, fontFamily: "MontserratMedium"),
                border: InputBorder.none,
              ),
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium"),
            ),
          ),
        ),
        SizedBox(height: 15),
        Container(
          height: (Get.height * 0.2).clamp(120.0, 150.0),
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: TextField(
            controller: controller.onYazi,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.done,
            maxLines: null,
            maxLength: 250,
            expands: true,
            decoration: InputDecoration(
              hintText: 'cv.about_hint'.tr,
              hintStyle: TextStyle(
                color: Colors.grey,
                fontFamily: "MontserratMedium",
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
      ],
    );
  }

  Widget step2() {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: controller.okullar.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.okullar.length) {
              return _buildAddRow(
                text: 'cv.add_school'.tr,
                onTap: () => controller.okulEkle(),
                margin: const EdgeInsets.only(top: 12),
              );
            }

            final model = controller.okullar[index];
            return Stack(
              children: [
                GestureDetector(
                  onTap: () => controller.okulDuzenle(index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(20),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(model.school,
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "MontserratBold")),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(model.branch,
                                      style: TextStyle(
                                          color: Colors.pinkAccent,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium")),
                                  if (model.branch.isNotEmpty &&
                                      model.lastYear.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      child: Text("-"),
                                    ),
                                  Text(controller.localizedYearLabel(
                                      model.lastYear),
                                      style: TextStyle(
                                          color: Colors.pinkAccent,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium")),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(CupertinoIcons.pencil,
                            color: Colors.grey, size: 18),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: GestureDetector(
                    onTap: () => controller.okulSil(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 3,
                              spreadRadius: 1)
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child:
                          Icon(Icons.close, size: 18, color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget step3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Skills / Beceriler ──
        SizedBox(height: 12),
        Row(
          children: [
            Text('cv.skills'.tr,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratBold")),
            SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
          ],
        ),
        SizedBox(height: 12),
        Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...controller.skills.asMap().entries.map((entry) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(entry.value,
                            style: TextStyle(
                                fontSize: 13,
                                fontFamily: "MontserratMedium",
                                color: Colors.blueAccent)),
                        SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => controller.skills.removeAt(entry.key),
                          child: Icon(Icons.close,
                              size: 16, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                  );
                }),
                if (controller.skills.length < 10)
                  GestureDetector(
                    onTap: () => controller.beceriEkle(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.add,
                            size: 15,
                            color: Colors.black,
                          ),
                          SizedBox(width: 4),
                          Text('social_links.add'.tr,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontFamily: "MontserratMedium",
                                  color: Colors.black)),
                        ],
                      ),
                    ),
                  ),
              ],
            )),

        SizedBox(height: 20),

        // ── Languages ──
        Row(
          children: [
            Text('cv.add_language'.tr,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratBold")),
            SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
          ],
        ),
        SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount:
              controller.diler.length >= 5 ? 5 : controller.diler.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.diler.length &&
                controller.diler.length < 5) {
              return _buildAddRow(
                text: 'cv.add_new_language'.tr,
                onTap: () => controller.dilEkle(),
                margin: EdgeInsets.only(top: index == 0 ? 0 : 12),
              );
            }

            final model = controller.diler[index];
            return GestureDetector(
              onTap: () => controller.dilDuzenle(index),
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(controller.localizedLanguage(model.languege),
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold")),
                          SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < model.level
                                    ? Icons.star
                                    : Icons.star_border,
                                color: i < model.level
                                    ? Colors.amber
                                    : Colors.grey,
                                size: 20,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(CupertinoIcons.pencil, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.diler.removeAt(index),
                      child: Icon(CupertinoIcons.trash,
                          color: Colors.redAccent, size: 20),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // ── Experience ──
        Row(
          children: [
            Text('cv.add_experience'.tr,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratBold")),
            SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
          ],
        ),
        SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: controller.isDeneyimleri.length >= 5
              ? 5
              : controller.isDeneyimleri.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.isDeneyimleri.length &&
                controller.isDeneyimleri.length < 5) {
              return _buildAddRow(
                text: 'cv.add_new_experience'.tr,
                onTap: () => controller.isDeneyimiEkle(),
                margin: EdgeInsets.only(top: index == 0 ? 0 : 12),
              );
            }

            final model = controller.isDeneyimleri[index];
            return GestureDetector(
              onTap: () => controller.isDeneyimiDuzenle(index),
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(model.position,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold")),
                          SizedBox(height: 4),
                          Text(model.company,
                              style: TextStyle(
                                  color: Colors.pinkAccent,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                          if (model.description.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Text(model.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                    fontFamily: "Montserrat")),
                          ],
                          SizedBox(height: 4),
                          Text(
                              "${controller.localizedYearLabel(model.year1)} - ${controller.localizedYearLabel(model.year2)}",
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(CupertinoIcons.pencil, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.isDeneyimleri.removeAt(index),
                      child: Icon(CupertinoIcons.trash,
                          color: Colors.redAccent, size: 20),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // ── References ──
        Row(
          children: [
            Text('cv.add_reference'.tr,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratBold")),
            SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
          ],
        ),
        SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: controller.referanslar.length >= 5
              ? 5
              : controller.referanslar.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.referanslar.length &&
                controller.referanslar.length < 5) {
              return _buildAddRow(
                text: 'cv.add_new_reference'.tr,
                onTap: () => controller.referansEkle(),
                margin: EdgeInsets.only(top: index == 0 ? 0 : 12),
              );
            }

            final model = controller.referanslar[index];
            return GestureDetector(
              onTap: () => controller.referansDuzenle(index),
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(model.nameSurname,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold")),
                          SizedBox(height: 4),
                          Text(model.phone,
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(CupertinoIcons.pencil, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.referanslar.removeAt(index),
                      child: Icon(CupertinoIcons.trash,
                          color: Colors.redAccent, size: 20),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
