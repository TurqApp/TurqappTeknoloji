part of 'deneme_sinavlari.dart';

extension DenemeSinavlariSectionsPart on DenemeSinavlari {
  Widget _buildEmptyState() {
    return AppStateView.empty(
      title: controller.hasActiveSearch
          ? 'practice.search_empty_title'.tr
          : 'practice.empty_title'.tr,
      message: controller.hasActiveSearch
          ? 'practice.search_empty_body_query'.tr
          : 'practice.empty_body'.tr,
      icon: Icons.quiz_outlined,
    );
  }

  Widget _buildExamTypeStrip() {
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: sinavTurleriList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(
              right: 25,
              left: index == 0 ? 20 : 0,
            ),
            child: GestureDetector(
              onTap: () {
                Get.to(
                  () => DenemeTurleriListesi(
                    sinavTuru: sinavTurleriList[index],
                  ),
                );
              },
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tumderslerColors[index],
                    ),
                    child: Icon(
                      dersler1icons[index],
                      color: Colors.white,
                    ),
                  ),
                  8.ph,
                  Text(
                    sinavTurleriList[index],
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

  Widget _buildSearchEntry() {
    return GestureDetector(
      onTap: () =>
          const PracticeExamNavigationService().openSearchPracticeExams(),
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(15),
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
                  const Icon(
                    AppIcons.search,
                    color: Colors.pink,
                  ),
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
}
