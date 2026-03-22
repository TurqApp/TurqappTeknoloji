part of 'my_tests.dart';

extension _MyTestsContentPart on _MyTestsState {
  Widget _buildContent() {
    if (controller.isLoading.value) {
      return const Center(
        child: CupertinoActivityIndicator(
          radius: 20,
          color: Colors.black,
        ),
      );
    }

    if (controller.list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.black,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              'tests.my_tests_empty'.tr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: 'Montserrat',
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 5.0,
          mainAxisSpacing: 5.0,
          childAspectRatio: 1.85 / 3.6,
        ),
        itemCount: controller.list.length,
        itemBuilder: (context, index) {
          return TestsGrid(
            model: controller.list[index],
            update: controller.getData,
          );
        },
      ),
    );
  }
}
