part of 'admin_push_view.dart';

extension AdminPushViewContentPart on _AdminPushViewState {
  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'MontserratMedium'),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black),
      ),
    );
  }

  Widget _buildPage(BuildContext context) {
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
            style: const TextStyle(
              color: Colors.black,
              fontFamily: 'MontserratSemiBold',
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
                  fontFamily: 'MontserratMedium',
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
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'MontserratSemiBold',
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 12),
            Text(
              'admin.push.help'.tr,
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: _input('admin.push.title_field'.tr),
              style: const TextStyle(fontFamily: 'MontserratMedium'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              decoration: _input('admin.push.message_field'.tr),
              style: const TextStyle(fontFamily: 'MontserratMedium'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: _input('admin.push.type'.tr),
              items: _pushTypes
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(fontFamily: 'MontserratMedium'),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                _updateViewState(() {
                  _selectedType = value;
                });
              },
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              collapsedShape: const RoundedRectangleBorder(
                side: BorderSide.none,
              ),
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text(
                'admin.push.optional_filters'.tr,
                style: const TextStyle(
                  fontFamily: 'MontserratSemiBold',
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
              children: [
                TextField(
                  controller: _uidController,
                  decoration: _input('admin.push.target_uid'.tr),
                  style: const TextStyle(fontFamily: 'MontserratMedium'),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _showMeslekSelector,
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: _input('admin.push.job'.tr),
                      controller: TextEditingController(text: _selectedMeslek),
                      style: const TextStyle(fontFamily: 'MontserratMedium'),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _konumController,
                  decoration: _input('admin.push.location_hint'.tr),
                  style: const TextStyle(fontFamily: 'MontserratMedium'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _genderController,
                  decoration: _input('admin.push.gender'.tr),
                  style: const TextStyle(fontFamily: 'MontserratMedium'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minAgeController,
                        keyboardType: TextInputType.number,
                        decoration: _input('admin.push.min_age'.tr),
                        style: const TextStyle(fontFamily: 'MontserratMedium'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _maxAgeController,
                        keyboardType: TextInputType.number,
                        decoration: _input('admin.push.max_age'.tr),
                        style: const TextStyle(fontFamily: 'MontserratMedium'),
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
                    fontFamily: 'MontserratMedium',
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            const SizedBox(height: 14),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text(
                'admin.push.saved_reports'.tr,
                style: const TextStyle(
                  fontFamily: 'MontserratSemiBold',
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
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
                          style: const TextStyle(
                            fontFamily: 'MontserratMedium',
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
                            (data['filters'] as Map<String, dynamic>? ??
                                <String, dynamic>{});
                        final ts = data['createdDate'];
                        DateTime? dt;
                        if (ts is Timestamp) dt = ts.toDate();
                        final timeText = dt == null
                            ? '-'
                            : "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} "
                                "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
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
                                  "$timeText | ${data['type'] ?? '-'} | ${data['targetCount'] ?? 0} ${'admin.push.people'.tr}\n"
                                  "${'admin.push.report_title'.tr}: ${data['title'] ?? '-'}\n"
                                  "${'admin.push.report_message'.tr}: ${(data['body'] ?? '-').toString()}\n"
                                  "${'admin.push.report_filters'.tr}: ${'admin.push.job'.tr}=${(filters['meslek'] ?? '-').toString().isEmpty ? '-' : filters['meslek']}, "
                                  "${'admin.push.location'.tr}=${(filters['konum'] ?? '-').toString().isEmpty ? '-' : filters['konum']}, "
                                  "${'admin.push.gender'.tr}=${(filters['cinsiyet'] ?? '-').toString().isEmpty ? '-' : filters['cinsiyet']}",
                                  style: const TextStyle(
                                    fontFamily: 'MontserratMedium',
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  await _adminPushRepository.deleteReport(
                                    report.id,
                                  );
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
                        style: const TextStyle(
                          fontFamily: 'MontserratSemiBold',
                        ),
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
