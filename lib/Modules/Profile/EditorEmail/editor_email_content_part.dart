part of 'editor_email.dart';

extension _EditorEmailContentPart on _EditorEmailState {
  Widget _buildEditorEmailContent() {
    final canSend = controller.countdown.value == 0 && !controller.isBusy.value;
    final canUpdate = controller.isCodeSent.value && !controller.isBusy.value;

    return Column(
      children: [
        Row(children: [BackButtons(text: 'editor_email.title'.tr)]),
        const SizedBox(height: 12),
        _buildEmailField(),
        const SizedBox(height: 12),
        TurqAppButton(
          onTap: () {
            if (canSend) {
              controller.sendEmailCode();
            }
          },
          bgColor: canSend ? Colors.black : Colors.grey,
          text: controller.countdown.value > 0
              ? 'editor_email.resend_in'
                  .trParams({'seconds': '${controller.countdown.value}'})
              : 'editor_email.send_code'.tr,
        ),
        const SizedBox(height: 10),
        Text(
          'editor_email.note'.tr,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 13,
            fontFamily: "MontserratMedium",
          ),
        ),
        if (controller.isCodeSent.value) ...[
          const SizedBox(height: 12),
          _buildCodeField(),
          const SizedBox(height: 10),
          TurqAppButton(
            onTap: () {
              if (canUpdate) {
                controller.verifyAndConfirmEmail();
              }
            },
            bgColor: canUpdate ? Colors.black : Colors.grey,
            text: 'editor_email.verify_confirm'.tr,
          ),
        ],
      ],
    );
  }

  Widget _buildEmailField() {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: TextField(
          controller: controller.emailController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'editor_email.email_hint'.tr,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontFamily: "MontserratMedium",
            ),
            border: InputBorder.none,
          ),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: "MontserratMedium",
          ),
        ),
      ),
    );
  }

  Widget _buildCodeField() {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: TextField(
          controller: controller.codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            counterText: "",
            hintText: 'editor_email.code_hint'.tr,
            hintStyle: const TextStyle(
              color: Colors.grey,
              fontFamily: "MontserratMedium",
            ),
            border: InputBorder.none,
          ),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: "MontserratMedium",
          ),
        ),
      ),
    );
  }
}
