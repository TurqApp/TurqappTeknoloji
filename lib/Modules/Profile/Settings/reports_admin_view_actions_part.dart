part of 'reports_admin_view.dart';

extension _ReportsAdminViewActionsPart on _ReportsAdminViewState {
  Future<void> _ensureConfig() async {
    if (_provisioning) return;
    _updateViewState(() => _provisioning = true);
    try {
      await _reportRepository.ensureConfigWithCallable();
      AppSnackbar('admin.reports.title'.tr, 'admin.reports.config_updated'.tr);
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.reports.config_failed'.tr}: $e',
      );
    } finally {
      _updateViewState(() => _provisioning = false);
    }
  }

  Future<void> _handleReview(String aggregateId, bool restore) async {
    if (_busyAggregateId.isNotEmpty) return;
    _updateViewState(() => _busyAggregateId = aggregateId);
    try {
      await _reportRepository.reviewAggregate(
        aggregateId: aggregateId,
        restore: restore,
      );
      AppSnackbar(
        'admin.reports.title'.tr,
        restore ? 'admin.reports.restored'.tr : 'admin.reports.kept_hidden'.tr,
      );
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.reports.action_failed'.tr}: $e',
      );
    } finally {
      _updateViewState(() => _busyAggregateId = '');
    }
  }
}
