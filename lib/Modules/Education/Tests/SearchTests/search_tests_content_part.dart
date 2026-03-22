part of 'search_tests.dart';

extension _SearchTestsContentPart on _SearchTestsState {
  Widget _buildGridContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Obx(
        () => controller.isLoading.value && controller.filteredList.isEmpty
            ? const EducationGridSkeleton(itemCount: 4)
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 5.0,
                  mainAxisSpacing: 5.0,
                  childAspectRatio: 2 / 4,
                ),
                itemCount: controller.filteredList.length,
                itemBuilder: (context, index) {
                  return TestsGrid(
                    model: controller.filteredList[index],
                  );
                },
              ),
      ),
    );
  }
}
