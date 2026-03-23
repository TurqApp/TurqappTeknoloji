part of 'ads_delivery_monitor_view.dart';

extension AdsDeliveryMonitorViewContentPart on AdsDeliveryMonitorView {
  Widget _buildPage(AdsCenterController controller) {
    return Obx(() {
      final logs = controller.deliveryLogs;
      if (logs.isEmpty) {
        return Center(
          child: Text(
            'ads_center.no_delivery_logs'.tr,
            style: const TextStyle(fontFamily: 'MontserratMedium'),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: logs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final log = logs[index];
          return _buildLogCard(log);
        },
      );
    });
  }
}
