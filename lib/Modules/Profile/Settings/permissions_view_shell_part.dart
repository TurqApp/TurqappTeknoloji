part of 'permissions_view.dart';

extension _PermissionsViewShellPart on _PermissionsViewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>(IntegrationTestKeys.screenPermissions),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: 'permissions.title'.tr),
            Expanded(
              child: _loading
                  ? const Center(child: CupertinoActivityIndicator())
                  : RefreshIndicator(
                      onRefresh: _refreshStatuses,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          Text(
                            'permissions.preferences'.tr,
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 13,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._items.map(_buildPermissionListItem),
                          const SizedBox(height: 10),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          Text(
                            'permissions.offline_space'.tr,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (int i = 0;
                                  i <
                                      _PermissionsViewState
                                          ._quotaOptions.length;
                                  i++) ...[
                                Expanded(
                                  child: _buildQuotaButton(
                                    _PermissionsViewState._quotaOptions[i],
                                  ),
                                ),
                                if (i !=
                                    _PermissionsViewState._quotaOptions.length -
                                        1)
                                  const SizedBox(width: 10),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'permissions.offline_space_desc'.tr,
                            style: const TextStyle(
                              color: Colors.black45,
                              fontSize: 13,
                              fontFamily: 'Montserrat',
                              height: 1.3,
                            ),
                          ),
                          _buildQuotaBreakdown(),
                          if (_showPlaybackPreferences)
                            _buildPlaybackPolicyCard(),
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
