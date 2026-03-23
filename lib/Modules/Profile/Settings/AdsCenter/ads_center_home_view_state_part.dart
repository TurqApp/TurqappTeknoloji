part of 'ads_center_home_view.dart';

extension AdsCenterHomeViewStatePart on _AdsCenterHomeViewState {
  Widget _buildAdminOnlyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'ads_center.admin_only'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'MontserratMedium',
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 32),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _controller.refreshAll,
              child: Text('common.retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
