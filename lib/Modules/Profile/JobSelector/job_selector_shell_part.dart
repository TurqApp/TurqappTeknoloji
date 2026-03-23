part of 'job_selector.dart';

extension JobSelectorShellPart on _JobSelectorState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [BackButtons(text: 'job_selector.title'.tr)],
                ),
                const SizedBox(height: 12),
                Text(
                  'job_selector.subtitle'.tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: "MontserratMedium",
                  ),
                ),
                const SizedBox(height: 12),
                _buildSearchField(),
                _buildJobList(),
                const SizedBox(height: 14),
                TurqAppButton(
                  text: 'common.save'.tr,
                  onTap: () {
                    controller.setData();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
