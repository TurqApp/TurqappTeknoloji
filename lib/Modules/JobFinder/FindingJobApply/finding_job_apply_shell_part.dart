part of 'finding_job_apply.dart';

extension FindingJobApplyShellPart on _FindingJobApplyState {
  Widget _buildFindingJobApplyBody() {
    return SafeArea(
      bottom: false,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    BackButtons(text: "pasaj.job_finder.finding_platform".tr),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: _buildFindingJobApplyContent(),
              ),
            ],
          ),
          _buildFindingJobIllustration(),
        ],
      ),
    );
  }

  Widget _buildFindingJobIllustration() {
    return Opacity(
      opacity: 0.5,
      child: Transform.translate(
        offset: const Offset(40, 10),
        child: Image.asset(
          "assets/images/cv.webp",
          height: Get.height / 4,
        ),
      ),
    );
  }
}
