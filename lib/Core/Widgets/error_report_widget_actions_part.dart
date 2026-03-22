part of 'error_report_widget.dart';

extension ErrorReportWidgetActionsPart on ErrorReportWidget {
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'error_report.just_now'.tr;
    } else if (difference.inHours < 1) {
      return 'error_report.minutes_ago'
          .trParams({'count': '${difference.inMinutes}'});
    } else if (difference.inDays < 1) {
      return 'error_report.hours_ago'
          .trParams({'count': '${difference.inHours}'});
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _showClearDialog(ErrorHandlingService errorService) {
    Get.defaultDialog(
      title: 'error_report.clear_title'.tr,
      middleText: 'error_report.clear_body'.tr,
      textConfirm: 'common.clear'.tr,
      textCancel: 'common.cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        errorService.clearErrorHistory();
        Get.back();
        AppSnackbar(
          'common.clear'.tr,
          'error_report.clear_success'.tr,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );
  }
}
