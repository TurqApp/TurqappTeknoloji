part of 'archives.dart';

extension ArchivesContentPart on _ArchivesState {
  Widget _buildArchiveList() {
    return RefreshIndicator(
      backgroundColor: Colors.black,
      color: Colors.white,
      onRefresh: controller.fetchData,
      child: ListView.builder(
        controller: controller.scrollController,
        itemCount: controller.list.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BackButtons(text: "settings.archive".tr),
            );
          }

          final actualIndex = index - 1;
          final model = controller.list[actualIndex];
          final itemKey = controller.getAgendaKey(docId: model.docID);
          final isCentered = controller.centeredIndex.value == actualIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Column(
              children: [
                AgendaContent(
                  key: itemKey,
                  model: model,
                  isPreview: false,
                  shouldPlay: isCentered,
                  instanceTag: controller.agendaInstanceTag(model.docID),
                  showArchivePost: true,
                ),
                const SizedBox(height: 2),
                Divider(color: Colors.grey.withAlpha(50)),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        BackButtons(text: "settings.archive".tr),
        EmptyRow(text: "common.no_results".tr),
      ],
    );
  }
}
