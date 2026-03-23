part of 'become_verified_account.dart';

extension _BecomeVerifiedAccountStepsPart on _BecomeVerifiedAccountState {
  Widget _buildVerifiedScaffold(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                AppBackButton(
                  onTap: () {
                    if (controller.bodySelection.value != 0) {
                      controller.bodySelection--;
                    } else {
                      Get.back();
                    }
                  },
                  icon: CupertinoIcons.arrow_left,
                  iconSize: 20,
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Obx(
                  () => Padding(
                    padding:
                        const EdgeInsets.only(left: 15, right: 15, bottom: 15),
                    child: _buildStepBody(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBody() {
    return switch (controller.bodySelection.value) {
      0 => build1(),
      1 => build2(),
      2 => build3(),
      3 => build4(),
      _ => const SizedBox.shrink(),
    };
  }
}
