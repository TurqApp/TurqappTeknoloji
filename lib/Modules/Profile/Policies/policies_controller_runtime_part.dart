part of 'policies_controller.dart';

void _handlePoliciesInit(PoliciesController controller) {
  unawaited(_loadPolicies(controller));
}

Future<void> _loadPolicies(PoliciesController controller) async {
  final doc = await ensureConfigRepository().getLegacyConfigDoc(
    collection: 'Yönetim',
    docId: 'Policies',
    preferCache: true,
  );
  if (doc == null) return;
  controller.privacyPolicy.value = (doc['privacy'] ?? '').toString();
  controller.eula.value = (doc['eula'] ?? '').toString();
  controller.ad.value = (doc['ad'] ?? '').toString();
}

void _handlePoliciesClose(PoliciesController controller) {
  controller.pageController.dispose();
}
