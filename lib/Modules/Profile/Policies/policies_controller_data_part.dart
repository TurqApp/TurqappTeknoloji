part of 'policies_controller.dart';

extension _PoliciesControllerDataPart on PoliciesController {
  Future<void> _loadPolicies() async {
    final doc = await ConfigRepository.ensure().getLegacyConfigDoc(
      collection: 'Yönetim',
      docId: 'Policies',
      preferCache: true,
    );
    if (doc == null) return;
    privacyPolicy.value = (doc["privacy"] ?? "").toString();
    eula.value = (doc["eula"] ?? "").toString();
    ad.value = (doc["ad"] ?? "").toString();
  }
}
