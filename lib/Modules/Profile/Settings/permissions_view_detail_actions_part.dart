part of 'permissions_view.dart';

extension _PermissionDetailActionsPart on _PermissionDetailViewState {
  Future<void> _onActionPressed() async {
    if (_busy) return;
    _updatePermissionDetailState(() => _busy = true);
    try {
      final canDirectRequest =
          _status.isDenied || _status.isLimited || _status.isProvisional;
      if (!_usesDeviceSettingStyle && canDirectRequest && !_enabled) {
        final next = await IntegrationPermissionTestHarness.request(
          widget.item.permission,
          permissionId: _permissionId(widget.item.permission),
        );
        _updatePermissionDetailState(() => _status = next);
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
