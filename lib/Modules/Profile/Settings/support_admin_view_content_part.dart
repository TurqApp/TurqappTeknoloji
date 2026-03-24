part of 'support_admin_view.dart';

extension _SupportAdminViewContentPart on _SupportAdminViewState {
  Future<void> _updateStatus(
    String docId, {
    required String status,
    String currentNote = '',
  }) async {
    final noteController = TextEditingController(text: currentNote);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(
          status == 'closed'
              ? 'admin.support.close_message'.tr
              : 'admin.support.answer_message'.tr,
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: noteController,
            maxLines: 4,
            placeholder: 'admin.support.note'.tr,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('common.cancel'.tr),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('common.save'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      noteController.dispose();
      return;
    }
    try {
      await _repository.setStatus(
        docId: docId,
        status: status,
        adminNote: noteController.text,
      );
      AppSnackbar(
        'admin.support.updated_title'.tr,
        'admin.support.updated_body'.tr,
      );
    } catch (e) {
      AppSnackbar('support.error_title'.tr, '${'support.error_body'.tr} $e');
    } finally {
      noteController.dispose();
    }
  }

  Widget _buildSupportAdminContent(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _repository.watchInbox(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CupertinoActivityIndicator(),
          );
        }
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'admin.support.empty'.tr,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 15,
                fontFamily: 'MontserratMedium',
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            return _buildInboxCard(context, docs[index]);
          },
        );
      },
    );
  }

  Widget _buildInboxCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final status = (data['status'] ?? 'open').toString();
    final adminNote = (data['adminNote'] ?? '').toString();
    final topic = (data['topic'] ?? '').toString();
    final nickname = (data['nickname'] ?? '').toString();
    final displayName = (data['displayName'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final userId = (data['userId'] ?? '').toString();
    final createdAt = data['createdAt'];
    final createdText =
        createdAt is Timestamp ? _formatDate(createdAt.toDate()) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: userId.trim().isEmpty
                      ? null
                      : () => Get.to(() => SocialProfile(userID: userId)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nickname.trim().isEmpty ? '@-' : '@$nickname',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: 'MontserratSemiBold',
                        ),
                      ),
                      if (displayName.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _statusBg(status),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 12,
                    fontFamily: 'MontserratSemiBold',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (topic.trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                topic,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontFamily: 'MontserratSemiBold',
                ),
              ),
            ),
          if (email.trim().isNotEmpty)
            Text(
              email,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontFamily: 'MontserratMedium',
              ),
            ),
          if (createdText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              createdText,
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 12,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            (data['message'] ?? '').toString(),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontFamily: 'MontserratMedium',
              height: 1.35,
            ),
          ),
          if (adminNote.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                adminNote,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontFamily: 'MontserratMedium',
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _updateStatus(
                    doc.id,
                    status: 'answered',
                    currentNote: adminNote,
                  ),
                  child: Text('admin.support.mark_answered'.tr),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _updateStatus(
                    doc.id,
                    status: 'closed',
                    currentNote: adminNote,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('admin.support.close'.tr),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  String _statusLabel(String status) {
    switch (status.trim()) {
      case 'answered':
        return 'admin.support.answered'.tr;
      case 'closed':
        return 'admin.support.closed'.tr;
      default:
        return 'admin.support.open'.tr;
    }
  }

  Color _statusColor(String status) {
    switch (status.trim()) {
      case 'answered':
        return const Color(0xFF2E7D32);
      case 'closed':
        return const Color(0xFF616161);
      default:
        return const Color(0xFF996800);
    }
  }

  Color _statusBg(String status) {
    switch (status.trim()) {
      case 'answered':
        return const Color(0xFFE8F7E9);
      case 'closed':
        return const Color(0xFFF0F0F0);
      default:
        return const Color(0xFFFFF3D8);
    }
  }
}
