part of 'deneme_turleri_listesi.dart';

extension DenemeTurleriListesiContentPart on _DenemeTurleriListesiState {
  Widget _buildDenemeTurleriListesiContent() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CupertinoActivityIndicator(radius: 20),
        );
      }

      if (controller.isInitialized.value && controller.list.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.black,
                  size: 40,
                ),
                const SizedBox(height: 10),
                Text(
                  'tests.not_found_in_type'
                      .trParams({'type': widget.sinavTuru}),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15,
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
        child: ListView(children: [_buildExamGrid()]),
      );
    });
  }

  Widget _buildExamGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 5.0,
          mainAxisSpacing: 5.0,
          childAspectRatio: 2 / 4,
        ),
        itemCount: controller.list.length,
        itemBuilder: (context, index) {
          return DenemeGrid(
            model: controller.list[index],
            getData: controller.getData,
          );
        },
      ),
    );
  }
}
