part of 'report_user.dart';

extension ReportUserSelectionPart on _ReportUserState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                if (controller.step.value == 0.50)
                  BackButtons(text: 'common.report'.tr)
                else
                  Row(
                    children: [
                      AppBackButton(
                        onTap: () {
                          controller.step.value = 0.5;
                        },
                        icon: CupertinoIcons.arrow_left,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppPageTitle(
                          'common.report'.tr,
                          fontSize: 25,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            Obx(
              () => LinearProgressIndicator(
                color: Colors.black,
                minHeight: 1,
                value: controller.step.value,
                backgroundColor: Colors.grey.withAlpha(20),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Obx(() {
                  return controller.step.value == 0.5
                      ? _buildSelectionStep()
                      : _buildResultStep();
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            children: [
              Text(
                'report.reported_user'.tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontFamily: 'MontserratBold',
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: Border.all(color: Colors.blueAccent),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 55,
                      height: 55,
                      child: controller.avatarUrl.value != ''
                          ? CachedNetworkImage(
                              imageUrl: controller.avatarUrl.value,
                              fit: BoxFit.cover,
                            )
                          : const Center(
                              child: CupertinoActivityIndicator(
                                  color: Colors.black),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.nickname.value,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          controller.fullName.value,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 15,
                            fontFamily: 'MontserratMedium',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            'report.what_issue'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'MontserratBold',
            ),
          ),
        ),
        const SizedBox(height: 27),
        for (final item in reportSelections) _buildSelectionItem(item),
        Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 25),
          child: TurqAppButton(
            bgColor: Colors.black,
            onTap: () {
              if (controller.selectedKey.value.isEmpty) return;
              controller.step.value = 1.0;
            },
            text: 'common.continue'.tr,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionItem(dynamic item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 15, right: 15),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            controller.selectedKey.value = item.key;
            controller.selectedTitle.value = item.title;
            controller.selectedDesc.value = item.description;
          },
          child: Container(
            decoration: BoxDecoration(
              color: controller.selectedTitle.value == item.title
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                        if (controller.selectedTitle.value == item.title)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              item.description,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: 'MontserratMedium',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: controller.selectedTitle.value == item.title
                          ? Colors.black
                          : Colors.white,
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      border: Border.all(
                        color: controller.selectedTitle.value == item.title
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                    child: controller.selectedTitle.value == item.title
                        ? const Icon(
                            CupertinoIcons.checkmark,
                            color: Colors.white,
                            size: 12,
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
