part of 'permissions_view.dart';

extension _PermissionDetailContentPart on _PermissionDetailViewState {
  Widget _buildPermissionDetailScaffold(BuildContext context) {
    final permissionId = _permissionId(widget.item.permission);
    return Scaffold(
      key: ValueKey<String>(
        IntegrationTestKeys.screenPermissionDetail(permissionId),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: widget.item.title),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...(_usesDeviceSettingStyle
                        ? _buildDeviceSettingBlocks()
                        : _buildPreferenceBlock()),
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: _showHelpSheet,
                      child: Text(
                        widget.item.helpText,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.black,
                            ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        key: ValueKey<String>(
                          IntegrationTestKeys.actionPermissionPrimary(
                            permissionId,
                          ),
                        ),
                        onPressed: _busy ? null : _onActionPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.black38,
                        ),
                        child: Text(
                          _busy ? 'permissions.checking'.tr : _buttonText,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadStatus() async {
    final status = await IntegrationPermissionTestHarness.statusFor(
      widget.item.permission,
      permissionId: _permissionId(widget.item.permission),
    );
    _updatePermissionDetailState(() => _status = status);
  }

  bool get _enabled => _status.isGranted || _status.isLimited;

  bool get _usesDeviceSettingStyle =>
      widget.item.permission == Permission.camera ||
      widget.item.permission == Permission.microphone ||
      widget.item.permission == Permission.notification;

  List<Widget> _buildPreferenceBlock() {
    return [
      Text(
        'permissions.detail.set_preferences'.tr,
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 15,
          fontFamily: 'MontserratMedium',
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'permissions.detail.preference_body'.trParams(<String, String>{
          'access': widget.item.accessText,
          'title': widget.item.title,
        }),
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 14,
          fontFamily: 'MontserratMedium',
          height: 1.2,
        ),
      ),
    ];
  }

  List<Widget> _buildDeviceSettingBlocks() {
    final currentStateTitle =
        _enabled ? 'permissions.allowed'.tr : 'permissions.denied'.tr;
    final otherStateTitle =
        _enabled ? 'permissions.denied'.tr : 'permissions.allowed'.tr;
    final currentStateDesc = _enabled
        ? 'permissions.detail.allowed_desc'
            .trParams(<String, String>{'access': widget.item.accessText})
        : 'permissions.detail.denied_desc'
            .trParams(<String, String>{'access': widget.item.accessText});
    final otherStateDesc = _enabled
        ? 'permissions.detail.denied_desc'
            .trParams(<String, String>{'access': widget.item.accessText})
        : 'permissions.detail.allowed_desc'
            .trParams(<String, String>{'access': widget.item.accessText});

    return [
      Text(
        'permissions.detail.device_setting'.tr,
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 15,
          fontFamily: 'MontserratMedium',
        ),
      ),
      const SizedBox(height: 8),
      Text(
        currentStateTitle,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontFamily: 'MontserratSemiBold',
          height: 1.0,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        currentStateDesc,
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 14,
          fontFamily: 'MontserratMedium',
          height: 1.2,
        ),
      ),
      const SizedBox(height: 26),
      Text(
        'permissions.detail.other_option'.tr,
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 15,
          fontFamily: 'MontserratMedium',
        ),
      ),
      const SizedBox(height: 8),
      Text(
        otherStateTitle,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontFamily: 'MontserratSemiBold',
          height: 1.0,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        otherStateDesc,
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 14,
          fontFamily: 'MontserratMedium',
          height: 1.2,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        'permissions.detail.go_device_settings'.tr,
        style: const TextStyle(
          color: Colors.black26,
          fontSize: 13,
          fontFamily: 'MontserratMedium',
        ),
      ),
    ];
  }
}
