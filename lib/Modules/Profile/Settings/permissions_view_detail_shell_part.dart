part of 'permissions_view.dart';

extension _PermissionDetailShellPart on _PermissionDetailViewState {
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
}
