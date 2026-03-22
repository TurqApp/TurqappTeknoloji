part of 'support_admin_view.dart';

extension _SupportAdminViewActionsPart on _SupportAdminViewState {
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
