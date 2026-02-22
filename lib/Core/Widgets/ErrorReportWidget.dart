import 'package:flutter/material.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
import 'package:get/get.dart';
import '../Services/ErrorHandlingService.dart';

class ErrorReportWidget extends StatelessWidget {
  const ErrorReportWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final errorService = Get.find<ErrorHandlingService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hata Raporu'),
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
          statusText = 'İyi';
          break;
        case 'fair':
          statusColor = Colors.orange;
          statusIcon = Icons.warning;
          statusText = 'Orta';
          break;
        case 'poor':
          statusColor = Colors.red;
          statusIcon = Icons.error;
          statusText = 'Kötü';
          break;
        default:
          statusColor = Colors.grey;
          statusIcon = Icons.help;
          statusText = 'Bilinmeyen';
      }

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: statusColor, size: 30),
                const SizedBox(width: 10),
                Text(
                  'Sistem Sağlığı: $statusText',
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
                  'Son 30 dk',
                  '${health['recentErrors']} hata',
                  Colors.blue,
                ),
                _buildHealthMetric(
                  'Kritik Hatalar',
                  '${health['criticalErrors']}',
                  Colors.red,
                ),
                _buildHealthMetric(
                  'Bağlantı',
                  health['isOnline'] ? 'Çevrimiçi' : 'Çevrimdışı',
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
                'Toplam Hata',
                '${stats['total']}',
                Icons.bug_report,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'Son 24 Saat',
                '${stats['last24Hours']}',
                Icons.schedule,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'Kritik',
                '${stats['critical']}',
                Icons.priority_high,
                Colors.red,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                'Tekrarlanabilir',
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
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
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 80, color: Colors.green),
              SizedBox(height: 20),
              Text(
                'Henüz hata kaydı yok',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              Text(
                'Sistem düzgün çalışıyor!',
                style: TextStyle(fontSize: 14, color: Colors.grey),
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
                'Tekrar Deneme: ${error.retryCount}',
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
                _buildDetailRow('Hata Kodu', error.code),
                _buildDetailRow('Kategori', error.category.label),
                _buildDetailRow('Önem Derecesi', error.severity.label),
                _buildDetailRow('Tekrarlanabilir', error.isRetryable ? 'Evet' : 'Hayır'),
                if (error.metadata.isNotEmpty)
                  _buildDetailRow('Metadata', error.metadata.toString()),
                if (error.stackTrace != null) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Stack Trace:',
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
      return 'Az önce';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} saat önce';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void _showClearDialog(ErrorHandlingService errorService) {
    Get.defaultDialog(
      title: 'Hata Geçmişini Temizle',
      middleText: 'Tüm hata kayıtları silinecek. Bu işlem geri alınamaz.',
      textConfirm: 'Temizle',
      textCancel: 'İptal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        errorService.clearErrorHistory();
        Get.back();
        AppSnackbar(
          'Temizlendi',
          'Hata geçmişi başarıyla temizlendi',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      },
    );
  }
}