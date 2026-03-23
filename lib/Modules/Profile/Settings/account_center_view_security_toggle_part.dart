part of 'account_center_view.dart';

extension AccountCenterViewSecurityTogglePart on _SessionSecuritySection {
  Widget _buildSecurityToggle(bool enabled) {
    return SwitchListTile.adaptive(
      key: const ValueKey<String>(
        IntegrationTestKeys.actionAccountCenterSingleDeviceToggle,
      ),
      value: enabled,
      onChanged: _handleSecurityToggleChanged,
      title: _buildSingleDeviceTitle(),
      subtitle: _buildSingleDeviceSubtitle(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
