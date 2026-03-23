part of 'account_center_view.dart';

extension AccountCenterViewPersonalLoadedPart on _PersonalDetailsSection {
  Widget _buildPersonalLoadedState(String? contactDetails) {
    return _PersonalDetailsCard(
      contactDetails: contactDetails,
      onContactTap: onContactTap,
    );
  }
}
