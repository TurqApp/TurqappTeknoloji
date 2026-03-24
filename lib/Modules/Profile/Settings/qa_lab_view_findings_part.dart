part of 'qa_lab_view.dart';

extension _QALabViewFindingsPart on _QALabViewState {
  Widget _buildFindingsCard() {
    return Obx(() {
      final findings = _recorder.buildPinpointFindings();
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
              if (findings.isEmpty)
                Text('settings.diagnostics.qa_no_findings'.tr),
              ...findings.take(20).map(
                    (finding) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '[${finding.severity.name}] ${finding.code}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${finding.surface} • ${finding.route}\n${finding.message}',
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
