part of 'sinav_sonuclarim.dart';

extension SinavSonuclarimContentPart on _SinavSonuclarimState {
  Widget _buildSinavSonuclarimContent() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CupertinoActivityIndicator(radius: 20),
        );
      }

      if (controller.list.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  size: 60,
                  color: Colors.grey,
                ),
                const SizedBox(height: 20),
                Text(
                  'practice.results_empty_title'.tr,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontFamily: "MontserratBold",
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'practice.results_empty_body'.tr,
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
        onRefresh: controller.findAndGetSinavlar,
        child: Container(
          color: Colors.white,
          child: ListView.builder(
            controller: controller.scrollController,
            itemCount: controller.list.length,
            itemBuilder: (context, index) {
              return DenemeGecmisSonucContent(
                index: index,
                model: controller.list[index],
              );
            },
          ),
        ),
      );
    });
  }
}
