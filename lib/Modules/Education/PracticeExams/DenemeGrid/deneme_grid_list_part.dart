part of 'deneme_grid.dart';

extension _DenemeGridListPart on DenemeGrid {
  Widget _buildListCard(
    DenemeGridController controller,
    SavedPracticeExamsController savedController,
  ) {
    const metrics = PasajListCardMetrics.regular;
    return GestureDetector(
      onTap: _openCard,
      child: Semantics(
        label: IntegrationTestKeys.practiceExamOpen(model.docID),
        button: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            key: ValueKey(
              IntegrationTestKeys.practiceExamOpen(model.docID),
            ),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
              color: Colors.white,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMedia(
                  width: metrics.mediaSize,
                  height: metrics.mediaSize,
                  radius: 10,
                ),
                const SizedBox(width: 10),
                _buildListDetails(controller, metrics),
                const SizedBox(width: 8),
                _buildListActionRail(controller, savedController, metrics),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
