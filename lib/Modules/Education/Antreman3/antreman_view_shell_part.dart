part of 'antreman_view.dart';

extension _AntremanViewShellPart on AntremanView2 {
  Widget _buildActionButton(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: ActionButton(
        context: context,
        menuItems: [
          PullDownMenuItem(
            title: 'pasaj.question_bank.solve_later'.tr,
            icon: CupertinoIcons.repeat,
            onTap: () {
              controller.fetchSavedQuestions();
              Get.to(() => ThenSolve());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              IconButton(
                onPressed: Get.back,
                icon: Icon(
                  AppIcons.arrowLeft,
                  color: Colors.black,
                  size: 25,
                ),
              ),
              TypewriterText(
                text: "pasaj.tabs.question_bank".tr,
              ),
            ],
          ),
        ),
        15.pw,
      ],
    );
  }
}
