part of 'archives.dart';

extension ArchivesShellPart on _ArchivesState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                final centeredIndex = controller.centeredIndex.value;
                controller.lastCenteredIndex = centeredIndex;
                if (controller.isLoading.value && controller.list.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  );
                }
                if (controller.list.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildArchiveList();
              }),
            ),
          ],
        ),
      ),
    );
  }
}
