part of 'answer_key.dart';

extension AnswerKeySectionsPart on AnswerKey {
  Widget _buildListingContent(List<dynamic> items) {
    return Column(
      children: [
        EducationSlider(
          sliderId: 'cevap_anahtari',
          imageList: [
            AppAssets.optical1,
            AppAssets.optical2,
            AppAssets.optical3,
          ],
        ),
        8.ph,
        _buildLessonsCategory(),
        if (!embedded) _buildSearch(),
        _buildListingBody(items),
      ],
    );
  }

  Widget _buildSearch() {
    return GestureDetector(
      onTap: () => Get.to(() => SearchAnswerKey()),
      child: Container(
        color: Colors.white,
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
                const SizedBox(width: 12),
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
    );
  }

  Widget _buildLessonsCategory() {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: controller.lessons.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 25, left: index == 0 ? 20 : 0),
            child: GestureDetector(
              onTap: () => Get.to(
                () => CategoryBasedAnswerKey(sinavTuru: dersler1[index]),
              ),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: controller.lessonsColors[index],
                    ),
                    child: Icon(
                      controller.lessonsIcons[index],
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _answerKeyExamLabel(controller.lessons[index]),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListingBody(List<dynamic> items) {
    if (controller.isLoading.value || controller.isSearchLoading.value) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (items.isEmpty) {
      return Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.only(top: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.black),
                  const SizedBox(height: 7),
                  Text(
                    controller.hasActiveSearch
                        ? 'answer_key.search_empty'.tr
                        : 'answer_key.no_optical_forms'.tr,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: controller.listingSelection.value == 0
            ? Column(
                children: PasajListingAdLayout.buildListChildren(
                  items: items,
                  itemBuilder: (item, index) => AnswerKeyContent(
                    key: ValueKey(item.docID),
                    model: item,
                    onUpdate: (v) => controller.refreshData(),
                    isListLayout: true,
                  ),
                  adBuilder: (slot) => AdmobKare(
                    key: ValueKey('answer-key-list-ad-$slot'),
                  ),
                ),
              )
            : Column(
                children: PasajListingAdLayout.buildTwoColumnGridChildren(
                  items: items,
                  horizontalSpacing: 4,
                  rowSpacing: 4,
                  itemBuilder: (item, index) => AnswerKeyContent(
                    key: ValueKey(item.docID),
                    model: item,
                    onUpdate: (v) => controller.refreshData(),
                  ),
                  adBuilder: (slot) => AdmobKare(
                    key: ValueKey('answer-key-grid-ad-$slot'),
                  ),
                ),
              ),
      ),
    );
  }
}
