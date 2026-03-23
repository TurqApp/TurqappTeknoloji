import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Repositories/report_repository.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';

part 'reports_admin_view_actions_part.dart';
part 'reports_admin_view_content_part.dart';
part 'reports_admin_view_shell_part.dart';

class ReportsAdminView extends StatefulWidget {
  const ReportsAdminView({super.key});

  @override
  State<ReportsAdminView> createState() => _ReportsAdminViewState();
}

class _ReportsAdminViewState extends State<ReportsAdminView> {
  final ReportRepository _reportRepository = ReportRepository.ensure();
  late final Future<bool> _canAccessFuture;
  bool _provisioning = false;
  String _busyAggregateId = '';

  @override
  void initState() {
    super.initState();
    _canAccessFuture = AdminAccessService.canAccessTask('reports');
  }

  void _updateViewState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
