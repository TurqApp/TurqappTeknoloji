part of 'optical_preview.dart';

extension OpticalPreviewIntroPart on _OpticalPreviewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Obx(() {
              if (controller.selection.value == 1) {
                return _buildExamView(context);
              }
              if (controller.selection.value == 0) {
                return _buildIntroView();
              }
              return const SizedBox();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroView() {
    return Container(
      color: Colors.white,
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  'answer_key.exam_started_title'.tr,
                  style: const TextStyle(
                    color: Colors.purple,
                    fontSize: 25,
                    fontFamily: 'MontserratBold',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'answer_key.exam_started_body'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'answer_key.exam_information_title'.tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: 'MontserratBold',
                  ),
                ),
                const SizedBox(height: 15),
                _buildStepRow('1-)', 'answer_key.exam_information_step1'.tr),
                const SizedBox(height: 15),
                _buildStepRow('2-)', 'answer_key.exam_information_step2'.tr),
                const SizedBox(height: 15),
                _buildInputField(
                  controller: controller.fullName,
                  hintText: 'answer_key.full_name_hint'.tr,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 15),
                _buildInputField(
                  controller: controller.ogrenciNo,
                  hintText: 'answer_key.student_number_hint'.tr,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: _handleStartPressed,
                  child: Container(
                    height: 45,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: controller.canStartTest()
                          ? Colors.indigo
                          : Colors.grey,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      'answer_key.start_now'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(String prefix, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: Text(
            prefix,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'MontserratBold',
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
  }) {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: TextField(
          controller: controller,
          maxLines: 1,
          keyboardType: keyboardType,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontFamily: 'MontserratMedium',
            ),
            border: InputBorder.none,
          ),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: 'MontserratMedium',
          ),
        ),
      ),
    );
  }

  void _handleStartPressed() {
    if (controller.fullName.text.trim().length < 6) {
      AppSnackbar(
        'signup.missing_info_title'.tr,
        'answer_key.full_name_required'.tr,
      );
      return;
    }
    if (controller.ogrenciNo.text.trim().isEmpty) {
      AppSnackbar(
        'signup.missing_info_title'.tr,
        'answer_key.student_number_required'.tr,
      );
      return;
    }
    controller.startTest();
  }
}
