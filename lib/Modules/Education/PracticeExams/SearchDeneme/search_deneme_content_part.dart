part of 'search_deneme.dart';

extension SearchDenemeContentPart on _SearchDenemeState {
  Widget _buildSearchContent() {
    if (controller.isLoading.value) {
      return const Center(
        child: CupertinoActivityIndicator(radius: 20),
      );
    }
    if (controller.filteredList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.quiz_outlined,
                size: 60,
                color: Colors.grey,
              ),
              const SizedBox(height: 20),
              Text(
                'practice.search_empty_title'.tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontFamily: "MontserratBold",
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                controller.searchController.text.isEmpty
                    ? 'practice.search_empty_body_empty'.tr
                    : 'practice.search_empty_body_query'.tr,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontFamily: "MontserratMedium",
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: Colors.white,
      backgroundColor: Colors.black,
      onRefresh: controller.getData,
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 0.52,
            ),
            itemCount: controller.filteredList.length,
            itemBuilder: (context, index) {
              return DenemeGrid(
                model: controller.filteredList[index],
                getData: controller.getData,
              );
            },
          ),
        ),
      ),
    );
  }
}
