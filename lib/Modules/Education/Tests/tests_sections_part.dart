part of 'tests.dart';

extension _TestsSectionsPart on _TestsState {
  Widget _buildTopContent() {
    return Column(
      children: [
        EducationSlider(
          imageList: [
            AppAssets.test1,
            AppAssets.test2,
            AppAssets.test3,
          ],
        ),
        20.ph,
        _buildLessonsRow(),
        if (!embedded) _buildSearchField(),
      ],
    );
  }

  Widget _buildLessonsRow() {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: dersler.length,
        itemBuilder: (context, index) {
          if (index >= dersRenkleri.length ||
              index >= derslerIconsOutlined.length) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: EdgeInsets.only(
              right: 7,
              left: index == 0 ? 20 : 0,
            ),
            child: GestureDetector(
              onTap: () => Get.to(
                () => LessonBasedTests(testTuru: dersler[index]),
              ),
              child: SizedBox(
                width: 70,
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: dersRenkleri[index],
                        borderRadius: const BorderRadius.all(
                          Radius.circular(40),
                        ),
                      ),
                      child: Icon(
                        derslerIconsOutlined[index],
                        color: Colors.white,
                      ),
                    ),
                    12.ph,
                    Text(
                      dersler[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return GestureDetector(
      onTap: () => const EducationTestNavigationService().openSearchTests(),
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, bottom: 15),
          child: Container(
            height: 50,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(AppIcons.search, color: Colors.pink),
                  12.pw,
                  Expanded(
                    child: Text(
                      'common.search'.tr,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(
        () => controller.isLoading.value
            ? const EducationGridSkeleton(itemCount: 4)
            : controller.list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'tests.no_shared'.tr,
                      style: const TextStyle(
                        fontFamily: 'MontserratMedium',
                        fontSize: 16,
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 5.0,
                      mainAxisSpacing: 5.0,
                      childAspectRatio: 0.48,
                    ),
                    itemCount: controller.list.length,
                    itemBuilder: (context, index) {
                      return TestsGrid(
                        key: ValueKey(controller.list[index].docID),
                        model: controller.list[index],
                      );
                    },
                  ),
      ),
    );
  }
}
