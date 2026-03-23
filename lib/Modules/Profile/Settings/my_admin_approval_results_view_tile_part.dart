part of 'my_admin_approval_results_view.dart';

class _ApprovalResultTile extends StatelessWidget {
  const _ApprovalResultTile({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'pending').toString().trim();
    final title = (data['title'] ?? 'admin.my_approvals.default_title'.tr)
        .toString()
        .trim();
    final summary = (data['summary'] ?? '').toString().trim();
    final targetNickname = (data['targetNickname'] ?? '').toString().trim();
    final resolvedByNickname =
        (data['resolvedByNickname'] ?? '').toString().trim();
    final rejectionReason = (data['rejectionReason'] ?? '').toString().trim();
    final createdAt = MyAdminApprovalResultsViewFormatPart.formatTimestamp(
      data['createdAt'],
    );
    final resolvedAt = MyAdminApprovalResultsViewFormatPart.formatTimestamp(
      data['resolvedAt'],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'MontserratBold',
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
              ),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            targetNickname.isEmpty ? summary : '@$targetNickname • $summary',
            style: const TextStyle(
              fontFamily: 'MontserratMedium',
              fontSize: 12,
              color: Colors.black87,
              height: 1.35,
            ),
          ),
          if (createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              '${'admin.my_approvals.requested'.tr}: $createdAt',
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ],
          if (resolvedAt != null || resolvedByNickname.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${'admin.my_approvals.result'.tr}: ${resolvedAt ?? '-'}${resolvedByNickname.isEmpty ? '' : ' • @$resolvedByNickname'}',
                style: const TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ),
          if (rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${'admin.approvals.rejection_reason'.tr}: $rejectionReason',
              style: const TextStyle(
                fontFamily: 'MontserratMedium',
                fontSize: 11,
                color: Colors.redAccent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
