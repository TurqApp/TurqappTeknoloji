part of 'qa_lab_view.dart';

extension _QALabViewRoutesPart on _QALabViewState {
  Widget _buildRoutesCard() {
    return Obx(() {
      final items = _recorder.routes.reversed.take(20).toList(growable: false);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'settings.diagnostics.qa_routes'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (items.isEmpty) Text('settings.diagnostics.qa_no_routes'.tr),
              ...items.map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(CupertinoIcons.arrow_right_arrow_left),
                  title: Text(item.current),
                  subtitle: Text('${item.previous} • ${item.surface}'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
