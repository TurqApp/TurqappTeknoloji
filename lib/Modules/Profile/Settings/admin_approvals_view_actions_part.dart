part of 'admin_approvals_view.dart';

extension _AdminApprovalsViewActionsPart on _ApprovalCardState {
  Future<void> _approve() async {
    if (_processing) return;
    _updateProcessing(true);
    try {
      final data = widget.doc.data();
      final type = (data['type'] ?? '').toString().trim();
      final payload = Map<String, dynamic>.from(
        (data['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      if (type == 'badge_change' || type == 'badge') {
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
            .httpsCallable('setUserBadgeByUserId');
        await callable.call<Map<String, dynamic>>(payload);
      } else if (type == 'user_ban') {
        final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
            .httpsCallable('setUserBanByUserId');
        await callable.call<Map<String, dynamic>>(payload);
      } else {
        throw Exception('unsupported_approval_type');
      }
      await _approvalRepository.approve(widget.doc.id);
      AppSnackbar(
        'admin.approvals.title'.tr,
        'admin.approvals.approved_body'.tr,
      );
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.approvals.approve_failed'.tr} $e',
      );
    } finally {
      _updateProcessing(false);
    }
  }

  Future<void> _reject() async {
    if (_processing) return;
    _updateProcessing(true);
    try {
      await _approvalRepository.reject(widget.doc.id);
      AppSnackbar(
        'admin.approvals.title'.tr,
        'admin.approvals.rejected_body'.tr,
      );
    } catch (e) {
      AppSnackbar(
        'support.error_title'.tr,
        '${'admin.approvals.reject_failed'.tr} $e',
      );
    } finally {
      _updateProcessing(false);
    }
  }

  String? _formatTimestamp(dynamic raw) {
    DateTime? date;
    if (raw is Timestamp) {
      date = raw.toDate();
    } else if (raw is int) {
      date = DateTime.fromMillisecondsSinceEpoch(raw);
    }
    if (date == null) return null;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year} ${two(date.hour)}:${two(date.minute)}';
  }
}
