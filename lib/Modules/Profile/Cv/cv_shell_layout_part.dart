part of 'cv.dart';

extension _CvShellLayoutPart on _CvState {
  Widget _buildCvShellLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const AppBackButton(),
        title: AppPageTitle('cv.title'.tr),
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
                _buildSaveButton(),
              ],
            ),
          );
        }),
      ),
    );
  }
}
