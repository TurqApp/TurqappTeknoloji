part of 'account_center_view.dart';

extension AccountCenterViewPersonalRowsPart on _PersonalDetailsCard {
  List<Widget> _buildPersonalRows() {
    return <Widget>[
      if (contactDetails != null)
        _PersonalDetailRow(
          title: 'account_center.contact_info'.tr,
          value: contactDetails!,
          onTap: onContactTap,
        ),
    ];
  }
}
