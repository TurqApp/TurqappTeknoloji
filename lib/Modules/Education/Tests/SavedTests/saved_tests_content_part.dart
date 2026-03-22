part of 'saved_tests.dart';

extension _SavedTestsContentPart on _SavedTestsState {
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
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EmptyRow(text: 'tests.saved_empty'.tr),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 5.0,
          mainAxisSpacing: 5.0,
          childAspectRatio: 1.85 / 3.6,
        ),
        itemCount: controller.list.length,
        itemBuilder: (context, index) {
          return TestsGrid(model: controller.list[index]);
        },
      ),
    );
  }
}
