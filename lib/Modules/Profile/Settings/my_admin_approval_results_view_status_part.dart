part of 'my_admin_approval_results_view.dart';

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      'approved' => Colors.green,
      'rejected' => Colors.redAccent,
      _ => Colors.orange,
    };
    final String label = switch (status) {
      'approved' => 'admin.approvals.approved'.tr,
      'rejected' => 'admin.approvals.rejected'.tr,
      _ => 'admin.approvals.pending'.tr,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'MontserratBold',
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}
