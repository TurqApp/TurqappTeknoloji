part of 'finding_job_apply.dart';

extension FindingJobApplyContentPart on _FindingJobApplyState {
  Widget _buildFindingJobApplyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "pasaj.job_finder.finding_how".tr,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontFamily: "MontserratMedium",
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "pasaj.job_finder.finding_body".tr,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontFamily: "Montserrat",
          ),
        ),
        const SizedBox(height: 12),
        Obx(_buildFindingJobActionCard),
      ],
    );
  }

  Widget _buildFindingJobActionCard() {
    if (controller.cvVar.value) {
      return GestureDetector(
        onTap: controller.toggleFindingJob,
        child: _buildActionContainer(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "pasaj.job_finder.looking_for_job".tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratMedium",
                  ),
                ),
              ),
              TurqAppToggle(isOn: controller.isFinding.value),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Get.to(() => Cv());
      },
      child: _buildActionContainer(
        child: Row(
          children: [
            Expanded(
              child: Text(
                "pasaj.job_finder.create_cv".tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: "MontserratMedium",
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: Colors.blueAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionContainer({required Widget child}) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: child,
      ),
    );
  }
}
