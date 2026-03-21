import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Repositories/admin_push_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/job_categories.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AdminPushView extends StatefulWidget {
  const AdminPushView({super.key});

  @override
  State<AdminPushView> createState() => _AdminPushViewState();
}

class _AdminPushViewState extends State<AdminPushView> {
  final AdminPushRepository _adminPushRepository = AdminPushRepository.ensure();
  final _uidController = TextEditingController();
  final _konumController = TextEditingController();
  final _genderController = TextEditingController();
  final _minAgeController = TextEditingController();
  final _maxAgeController = TextEditingController();
  late final TextEditingController _titleController;
  final _bodyController = TextEditingController();
  final List<String> _pushTypes = const [
    "posts",
    "follow",
    "comment",
    "message",
    "like",
    "reshared_posts",
    "shared_as_posts",
  ];
  String _selectedType = "posts";
  String _selectedMeslek = "";
  bool _sending = false;
  bool _checkingAccess = true;
  bool _canManagePush = false;
  String _lastReport = "";

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'app.name'.tr);
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final allowed = await AdminAccessService.canAccessTask('admin_push');
    if (!mounted) return;
    setState(() {
      _canManagePush = allowed;
      _checkingAccess = false;
    });
  }

  @override
  void dispose() {
    _uidController.dispose();
    _konumController.dispose();
    _genderController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _showMeslekSelector() async {
    await Get.bottomSheet(
      ListBottomSheet(
        list: allJobs,
        title: 'admin.push.select_job'.tr,
        startSelection: _selectedMeslek,
        onBackData: (v) {
          if (v is String) {
            setState(() {
              _selectedMeslek = v;
            });
          }
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
    );
  }

  Future<List<String>> _resolveTargetUids({
    required String uid,
    required String meslek,
    required String konum,
    required String gender,
    required int? minAge,
    required int? maxAge,
  }) async {
    return _adminPushRepository.resolveTargetUids(
      filters: AdminPushTargetFilters(
        uid: uid,
        meslek: meslek,
        konum: konum,
        gender: gender,
        minAge: minAge,
        maxAge: maxAge,
      ),
    );
  }

  Future<void> _sendPush() async {
    if (!_canManagePush) {
      AppSnackbar(
        'admin.push.permission_title'.tr,
        'admin.push.permission_body'.tr,
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final uid = _uidController.text.trim();
    final meslek = _selectedMeslek.trim();
    final konum = _konumController.text.trim();
    final gender = _genderController.text.trim();
    final minAge = int.tryParse(_minAgeController.text.trim());
    final maxAge = int.tryParse(_maxAgeController.text.trim());
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final type = _selectedType;

    if (title.isEmpty || body.isEmpty) {
      AppSnackbar(
        'admin.tasks.missing_info'.tr,
        'admin.push.required_title_body'.tr,
      );
      return;
    }
    if (minAge != null && maxAge != null && minAge > maxAge) {
      AppSnackbar(
        'admin.push.invalid_range_title'.tr,
        'admin.push.invalid_range_body'.tr,
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final targetUids = await _resolveTargetUids(
        uid: uid,
        meslek: meslek,
        konum: konum,
        gender: gender,
        minAge: minAge,
        maxAge: maxAge,
      );
      final senderUid = CurrentUserService.instance.userId.trim().isEmpty
          ? "admin"
          : CurrentUserService.instance.userId.trim();

      if (targetUids.isEmpty) {
        AppSnackbar(
          'admin.push.no_results_title'.tr,
          'admin.push.no_results_body'.tr,
        );
        return;
      }

      await _adminPushRepository.sendPush(
        title: title,
        body: body,
        type: type,
        targetUids: targetUids,
      );

      if (!mounted) return;
      setState(() {
        final now = DateTime.now();
        _lastReport =
            "Saat ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}\n"
            "${'admin.push.target'.tr}: ${targetUids.length} ${'admin.push.user_count'.tr}\n"
            "${'admin.push.type'.tr}: $type\n"
            "UID: ${uid.isEmpty ? '-' : uid}\n"
            "${'admin.push.job'.tr}: ${meslek.isEmpty ? '-' : meslek}\n"
            "${'admin.push.location'.tr}: ${konum.isEmpty ? '-' : konum}\n"
            "${'admin.push.gender'.tr}: ${gender.isEmpty ? '-' : gender}\n"
            "${'admin.push.age'.tr}: ${minAge?.toString() ?? '-'} - ${maxAge?.toString() ?? '-'}";
      });
      try {
        await _adminPushRepository.addReport(
          senderUid: senderUid,
          title: title,
          body: body,
          type: type,
          targetCount: targetUids.length,
          filters: AdminPushTargetFilters(
            uid: uid,
            meslek: meslek,
            konum: konum,
            gender: gender,
            minAge: minAge,
            maxAge: maxAge,
          ),
        );
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
      }
      AppSnackbar(
        'admin.push.started_title'.tr,
        'admin.push.started_body'
            .trParams(<String, String>{'count': '${targetUids.length}'}),
      );
      _bodyController.clear();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.push.send_failed'.tr}: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: "MontserratMedium"),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAccess) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_canManagePush) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'admin.push.title'.tr,
            style: TextStyle(
              color: Colors.black,
              fontFamily: "MontserratSemiBold",
              fontSize: 20,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'admin.no_access'.tr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: "MontserratMedium",
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'admin.push.title'.tr,
          style: TextStyle(
            color: Colors.black,
            fontFamily: "MontserratSemiBold",
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'admin.push.help'.tr,
              style: const TextStyle(
                fontFamily: "MontserratMedium",
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: _input('admin.push.title_field'.tr),
              style: const TextStyle(fontFamily: "MontserratMedium"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              decoration: _input('admin.push.message_field'.tr),
              style: const TextStyle(fontFamily: "MontserratMedium"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: _input('admin.push.type'.tr),
              items: _pushTypes
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(
                        e,
                        style: const TextStyle(fontFamily: "MontserratMedium"),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedType = v;
                });
              },
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'admin.push.optional_filters'.tr,
                style: const TextStyle(
                  fontFamily: "MontserratSemiBold",
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                TextField(
                  controller: _uidController,
                  decoration: _input("admin.push.target_uid".tr),
                  style: const TextStyle(fontFamily: "MontserratMedium"),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _showMeslekSelector,
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: _input('admin.push.job'.tr),
                      controller: TextEditingController(
                        text: _selectedMeslek,
                      ),
                      style: const TextStyle(fontFamily: "MontserratMedium"),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _konumController,
                  decoration: _input('admin.push.location_hint'.tr),
                  style: const TextStyle(fontFamily: "MontserratMedium"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _genderController,
                  decoration: _input('admin.push.gender'.tr),
                  style: const TextStyle(fontFamily: "MontserratMedium"),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minAgeController,
                        keyboardType: TextInputType.number,
                        decoration: _input('admin.push.min_age'.tr),
                        style: const TextStyle(fontFamily: "MontserratMedium"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _maxAgeController,
                        keyboardType: TextInputType.number,
                        decoration: _input('admin.push.max_age'.tr),
                        style: const TextStyle(fontFamily: "MontserratMedium"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_lastReport.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                  color: Colors.grey.shade100,
                ),
                child: Text(
                  _lastReport,
                  style: const TextStyle(
                    fontFamily: "MontserratMedium",
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'admin.push.saved_reports'.tr,
                style: const TextStyle(
                  fontFamily: "MontserratSemiBold",
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                StreamBuilder<List<AdminPushReport>>(
                  stream: _adminPushRepository.watchReports(limit: 20),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final docs = snap.data!;
                    if (docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Text(
                          'admin.push.no_reports'.tr,
                          style: TextStyle(
                            fontFamily: "MontserratMedium",
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: docs.map((report) {
                        final data = report.data;
                        final filters =
                            (data["filters"] as Map<String, dynamic>? ??
                                <String, dynamic>{});
                        final ts = data["createdDate"];
                        DateTime? dt;
                        if (ts is Timestamp) dt = ts.toDate();
                        final timeText = dt == null
                            ? "-"
                            : "${dt.day.toString().padLeft(2, "0")}.${dt.month.toString().padLeft(2, "0")} "
                                "${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}";
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                            color: Colors.grey.shade100,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  "$timeText | ${data["type"] ?? "-"} | ${data["targetCount"] ?? 0} ${'admin.push.people'.tr}\n"
                                  "${'admin.push.report_title'.tr}: ${data["title"] ?? "-"}\n"
                                  "${'admin.push.report_message'.tr}: ${(data["body"] ?? "-").toString()}\n"
                                  "${'admin.push.report_filters'.tr}: ${'admin.push.job'.tr}=${(filters["meslek"] ?? "-").toString().isEmpty ? "-" : filters["meslek"]}, "
                                  "${'admin.push.location'.tr}=${(filters["konum"] ?? "-").toString().isEmpty ? "-" : filters["konum"]}, "
                                  "${'admin.push.gender'.tr}=${(filters["cinsiyet"] ?? "-").toString().isEmpty ? "-" : filters["cinsiyet"]}",
                                  style: const TextStyle(
                                    fontFamily: "MontserratMedium",
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await _adminPushRepository
                                      .deleteReport(report.id);
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.black54,
                                  size: 20,
                                ),
                                tooltip: 'admin.push.delete_report'.tr,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _sending ? null : _sendPush,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'admin.push.send'.tr,
                        style: TextStyle(fontFamily: "MontserratSemiBold"),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
