part of 'create_test_question_content.dart';

extension CreateTestQuestionContentShellPart
    on _CreateTestQuestionContentState {
  Widget _buildQuestionContent(BuildContext context) {
    return Obx(
      () => controller.isInvalid.value
          ? _buildInvalidState()
          : Padding(
              padding: EdgeInsets.only(
                bottom: 20,
                top: index == 0 ? 20 : 0,
                left: 20,
                right: 20,
              ),
              child: Stack(
                alignment: Alignment.topLeft,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.5),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildImageSection(context),
                        const Divider(),
                        _buildChoiceSection(),
                      ],
                    ),
                  ),
                  _buildQuestionBadge(),
                ],
              ),
            ),
    );
  }

  Widget _buildInvalidState() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, color: Colors.black, size: 40),
          const SizedBox(height: 10),
          Text(
            "tests.question_content_failed".tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: "Montserrat",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    if (controller.isLoading.value) {
      return const Center(
        child: CupertinoActivityIndicator(
          radius: 20,
          color: Colors.black,
        ),
      );
    }
    if (controller.selectedImage.value != null) {
      return GestureDetector(
        onTap: () {},
        child: Image.file(controller.selectedImage.value!),
      );
    }
    if (controller.model.img.isEmpty) {
      return _buildEmptyImageState(context);
    }
    return CachedNetworkImage(
      imageUrl: controller.model.img,
      key: ValueKey(controller.model.img),
      placeholder: (context, url) => const Center(
        child: CupertinoActivityIndicator(),
      ),
      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
    );
  }

  Widget _buildEmptyImageState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Image.asset(
            "assets/createsoru.webp",
            height:
                (MediaQuery.of(context).size.height * 0.24).clamp(140.0, 180.0),
          ),
          const SizedBox(height: 15),
          Text(
            "tests.capture_and_upload".tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 25,
              fontFamily: "MontserratBold",
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              "tests.capture_and_upload_body".tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontFamily: "MontserratMedium",
              ),
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.only(
              left: 30,
              right: 30,
              top: 20,
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: controller.pickImageFromGallery,
                    child: _buildImageActionButton(
                      label: "tests.select_from_gallery".tr,
                      color: Colors.pink,
                      fontFamily: "MontserratMedium",
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: controller.pickImageFromGallery,
                    child: _buildImageActionButton(
                      label: "tests.upload_from_camera".tr,
                      color: Colors.indigo,
                      fontFamily: "MontserratBold",
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageActionButton({
    required String label,
    required Color color,
    required String fontFamily,
    required double fontSize,
  }) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  Widget _buildQuestionBadge() {
    return Transform.translate(
      offset: const Offset(-15, -15),
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.indigo,
        ),
        child: Text(
          (index + 1).toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontFamily: "MontserratBold",
          ),
        ),
      ),
    );
  }
}
