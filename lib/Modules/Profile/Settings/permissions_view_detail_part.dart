part of 'permissions_view.dart';

extension _PermissionDetailPart on _PermissionDetailViewState {
  Future<void> _loadStatus() async {
    final status = await widget.item.permission.status;
    _updatePermissionDetailState(() => _status = status);
  }

  bool get _enabled => _status.isGranted || _status.isLimited;

  bool get _usesDeviceSettingStyle =>
      widget.item.permission == Permission.camera ||
      widget.item.permission == Permission.microphone ||
      widget.item.permission == Permission.notification;

  Future<void> _onActionPressed() async {
    if (_busy) return;
    _updatePermissionDetailState(() => _busy = true);
    try {
      final canDirectRequest =
          _status.isDenied || _status.isLimited || _status.isProvisional;
      if (!_usesDeviceSettingStyle && canDirectRequest && !_enabled) {
        await widget.item.permission.request();
        await _loadStatus();
      } else {
        final shouldOpen = await _confirmOpenSettings();
        if (shouldOpen) {
          await openAppSettings();
        }
      }
    } finally {
      _updatePermissionDetailState(() => _busy = false);
    }
  }

  Future<bool> _confirmOpenSettings() async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: Text('permissions.dialog.update_device_settings'.tr),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'permissions.dialog.update_body'.trParams(
                <String, String>{'title': widget.item.title},
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(true),
              isDefaultAction: true,
              child: Text('permissions.dialog.open_settings'.tr),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('permissions.dialog.not_now'.tr),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  String get _buttonText {
    if (_usesDeviceSettingStyle) {
      return 'permissions.dialog.update_device_settings'.tr;
    }
    final canDirectRequest =
        _status.isDenied || _status.isLimited || _status.isProvisional;
    if (!_enabled && canDirectRequest) return 'permissions.enable'.tr;
    if (widget.item.permission == Permission.locationWhenInUse && !_enabled) {
      return 'permissions.enable_location'.tr;
    }
    return 'permissions.dialog.update_device_settings'.tr;
  }

  Widget _buildPermissionDetailScaffold(BuildContext context) {
    return Scaffold(
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

  void _showHelpSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    widget.item.helpSheetTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 24,
                      fontFamily: 'MontserratBold',
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.item.helpSheetBody,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontFamily: 'MontserratMedium',
                    height: 1.25,
                  ),
                ),
                if (widget.item.helpSheetBody2 != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.item.helpSheetBody2!,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontFamily: 'MontserratMedium',
                      height: 1.25,
                    ),
                  ),
                ],
                if (widget.item.helpSheetLinkText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.item.helpSheetLinkText!,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
