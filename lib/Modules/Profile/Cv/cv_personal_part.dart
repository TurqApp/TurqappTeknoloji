part of 'cv.dart';

extension _CvPersonalPart on _CvState {
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
                        color: Colors.grey,
                        fontFamily: "MontserratMedium",
                      ),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
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
                        color: Colors.grey,
                        fontFamily: "MontserratMedium",
                      ),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratMedium",
                    ),
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
                  color: Colors.grey,
                  fontFamily: "MontserratMedium",
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
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
                  color: Colors.grey,
                  fontFamily: "MontserratMedium",
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
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
}
