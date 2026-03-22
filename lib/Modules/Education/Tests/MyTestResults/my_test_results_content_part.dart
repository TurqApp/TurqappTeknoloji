part of 'my_test_results.dart';

extension _MyTestResultsContentPart on _MyTestResultsState {
  Widget _buildContent() {
    if (controller.isLoading.value) {
      return const Center(child: CupertinoActivityIndicator());
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
              'tests.my_results_empty'.tr,
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

    return ListView.builder(
      itemCount: controller.list.length,
      itemBuilder: (context, index) {
        return TestPastResultContent(
          index: index,
          model: controller.list[index],
        );
      },
    );
  }
}
