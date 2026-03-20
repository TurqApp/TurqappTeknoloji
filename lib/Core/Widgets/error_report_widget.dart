import 'package:flutter/material.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:get/get.dart';
import '../Services/error_handling_service.dart';

class ErrorReportWidget extends StatelessWidget {
  const ErrorReportWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final errorService = Get.find<ErrorHandlingService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('error_report.title'.tr),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showClearDialog(errorService),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHealthCard(errorService),
          _buildStatsCards(errorService),
          Expanded(child: _buildErrorList(errorService)),
        ],
      ),
    );
  }

  Widget _buildHealthCard(ErrorHandlingService errorService) {
    return Obx(() {
      final health = errorService.getSystemHealth();
      final status = health['status'] as String;

      Color statusColor;
      IconData statusIcon;
      String statusText;

      switch (status) {
        case 'good':
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          statusText = 'error_report.status_good'.tr;
          break;
        case 'fair':
          statusColor = Colors.orange;
          statusIcon = Icons.warning;
          statusText = 'error_report.status_fair'.tr;
          break;
        case 'poor':
          statusColor = Colors.red;
          statusIcon = Icons.error;
          statusText = 'error_report.status_poor'.tr;
          break;
        default:
          statusColor = Colors.grey;
          statusIcon = Icons.help;
          statusText = 'error_report.status_unknown'.tr;
      }

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              statusColor.withValues(alpha: 0.1),
              statusColor.withValues(alpha: 0.05)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: statusColor, size: 30),
                const SizedBox(width: 10),
                Text(
                  'error_report.system_health'.trParams({'status': statusText}),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHealthMetric(
                  'error_report.last_30_minutes'.tr,
                  'error_report.error_count'
                      .trParams({'count': '${health['recentErrors']}'}),
                  Colors.blue,
                ),
                _buildHealthMetric(
                  'error_report.critical_errors'.tr,
                  '${health['criticalErrors']}',
                  Colors.red,
                ),
                _buildHealthMetric(
                  'error_report.connection'.tr,
                  health['isOnline']
                      ? 'error_report.online'.tr
                      : 'error_report.offline'.tr,
                  health['isOnline'] ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHealthMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(ErrorHandlingService errorService) {
    return Obx(() {
      final stats = errorService.getErrorStats();

      return Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'error_report.total_errors'.tr,
                '${stats['total']}',
                Icons.bug_report,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'error_report.last_24_hours'.tr,
                '${stats['last24Hours']}',
                Icons.schedule,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'error_report.critical'.tr,
                '${stats['critical']}',
                Icons.priority_high,
                Colors.red,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'error_report.retryable'.tr,
                '${stats['retryableErrors']}',
                Icons.refresh,
                Colors.green,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorList(ErrorHandlingService errorService) {
    return Obx(() {
      final errors = errorService.errorHistory.reversed.toList();

      if (errors.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              Text(
                'error_report.empty_title'.tr,
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              Text(
                'error_report.empty_body'.tr,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: errors.length,
        itemBuilder: (context, index) => _buildErrorItem(errors[index]),
      );
    });
  }

  Widget _buildErrorItem(AppError error) {
    Color severityColor;
    IconData severityIcon;

    switch (error.severity) {
      case ErrorSeverity.critical:
        severityColor = Colors.red;
        severityIcon = Icons.dangerous;
        break;
      case ErrorSeverity.high:
        severityColor = Colors.orange;
        severityIcon = Icons.warning;
        break;
      case ErrorSeverity.medium:
        severityColor = Colors.amber;
        severityIcon = Icons.info;
        break;
      case ErrorSeverity.low:
        severityColor = Colors.blue;
        severityIcon = Icons.info_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(severityIcon, color: severityColor),
        title: Text(
          error.userFriendlyMessage,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${error.category.label} • ${_formatTime(error.timestamp)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (error.retryCount > 0)
              Text(
                'error_report.retry_count'
                    .trParams({'count': '${error.retryCount}'}),
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('error_report.error_code'.tr, error.code),
                _buildDetailRow('error_report.category'.tr, error.category.label),
                _buildDetailRow('error_report.severity'.tr, error.severity.label),
                _buildDetailRow(
                    'error_report.retryable'.tr,
                    error.isRetryable ? 'common.yes'.tr : 'common.no'.tr),
                if (error.metadata.isNotEmpty)
                  _buildDetailRow('error_report.metadata'.tr, error.metadata.toString()),
                if (error.stackTrace != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'error_report.stack_trace'.tr,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      error.stackTrace!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

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
