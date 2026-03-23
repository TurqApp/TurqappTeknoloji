part of 'account_center_view.dart';

class _PersonalDetailsCard extends StatelessWidget {
  const _PersonalDetailsCard({
    required this.contactDetails,
    required this.onContactTap,
  });

  final String? contactDetails;
  final VoidCallback onContactTap;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (contactDetails != null)
        _PersonalDetailRow(
          title: 'account_center.contact_info'.tr,
          value: contactDetails!,
          onTap: onContactTap,
        ),
    ];

    if (rows.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Text(
          'account_center.no_personal_detail'.tr,
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
            fontFamily: 'MontserratMedium',
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1)
              const Divider(height: 1, indent: 18, endIndent: 18),
          ],
        ],
      ),
    );
  }
}
