part of 'lesson_based_tests.dart';

extension _LessonBasedTestsContentPart on _LessonBasedTestsState {
  Widget _buildContent() {
    final filtered = controller.list
        .where((test) => test.testTuru == testTuru)
        .toList(growable: false);

    if (controller.isLoading.value) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (filtered.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.black,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'tests.none_in_category'.tr,
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
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 5.0,
          mainAxisSpacing: 5.0,
          childAspectRatio: 1.85 / 3.6,
        ),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          return TestsGrid(
            model: filtered[index],
            update: controller.getData,
          );
        },
      ),
    );
  }
}
