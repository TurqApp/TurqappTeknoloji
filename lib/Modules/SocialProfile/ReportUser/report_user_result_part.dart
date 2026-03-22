part of 'report_user.dart';

extension ReportUserResultPart on _ReportUserState {
  Widget _buildResultStep() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: 'report.thanks_title'.tr,
            body: 'report.thanks_body'.tr,
            titleSize: 25,
          ),
          _buildSection(
            title: 'report.how_it_works_title'.tr,
            body: 'report.how_it_works_body'.tr,
          ),
          _buildSection(
            title: 'report.whats_next_title'.tr,
            body: 'report.whats_next_body'.tr,
          ),
          _buildSection(
            title: 'report.optional_block_title'.tr,
            body: 'report.optional_block_body'.tr,
          ),
          if (!controller.blockedUser.value)
            GestureDetector(
              onTap: controller.block,
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'report.block_user_button'.trParams({
                    'nickname': controller.nickname.value,
                  }),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
              ),
            )
          else
            Text(
              'report.blocked_user_label'.trParams({
                'nickname': controller.nickname.value,
              }),
              style: const TextStyle(
                color: Colors.red,
                fontSize: 15,
                fontFamily: 'MontserratMedium',
                fontStyle: FontStyle.italic,
                decoration: TextDecoration.underline,
              ),
            ),
          const SizedBox(height: 15),
          Text(
            'report.block_user_info'.trParams({
              'nickname': controller.nickname.value,
            }),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontFamily: 'MontserratMedium',
            ),
          ),
          const SizedBox(height: 12),
          Obx(
            () => TurqAppButton(
              onTap: controller.report,
              text: controller.isSubmitting.value
                  ? 'report.submitting'.tr
                  : 'report.done'.tr,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String body,
    double titleSize = 18,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.black,
              fontSize: titleSize,
              fontFamily: 'MontserratBold',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 15,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ],
      ),
    );
  }
}
