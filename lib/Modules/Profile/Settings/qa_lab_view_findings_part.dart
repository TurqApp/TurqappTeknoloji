part of 'qa_lab_view.dart';

extension _QALabViewFindingsPart on _QALabViewState {
  Widget _buildFindingsCard() {
    return Obx(() {
      final findings = _recorder.buildPinpointFindings();
      final visible = findings.take(20).toList(growable: false);

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'settings.diagnostics.qa_findings'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                Text('settings.diagnostics.qa_no_findings'.tr),
              ...visible.map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    switch (item.severity) {
                      QALabIssueSeverity.blocking => CupertinoIcons.xmark_octagon_fill,
                      QALabIssueSeverity.error => CupertinoIcons.exclamationmark_triangle_fill,
                      QALabIssueSeverity.warning => CupertinoIcons.exclamationmark_circle_fill,
                      QALabIssueSeverity.info => CupertinoIcons.info_circle_fill,
                    },
                    color: switch (item.severity) {
                      QALabIssueSeverity.blocking => Colors.red.shade700,
                      QALabIssueSeverity.error => Colors.red.shade400,
                      QALabIssueSeverity.warning => Colors.orange.shade700,
                      QALabIssueSeverity.info => Colors.blueGrey,
                    },
                  ),
                  title: Text(
                    '${item.surface} • ${item.code}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${item.message}\nroute=${item.route.isEmpty ? "-" : item.route}',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
