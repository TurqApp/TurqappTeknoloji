import 'package:flutter/material.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:get/get.dart';
import '../Services/error_handling_service.dart';

part 'error_report_widget_content_part.dart';
part 'error_report_widget_actions_part.dart';

class ErrorReportWidget extends StatelessWidget {
  const ErrorReportWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final errorService = ensureErrorHandlingService();

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
}
