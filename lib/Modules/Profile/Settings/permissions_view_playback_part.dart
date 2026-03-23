part of 'permissions_view.dart';

extension _PermissionsViewPlaybackPart on _PermissionsViewState {
  Future<void> _loadNetworkSettings() async {
    final networkService = NetworkAwarenessService.maybeFind();
    if (networkService == null) return;
    final settings = networkService.settings;
    _updatePermissionsViewState(() {
      _networkSettings = NetworkSettings(
        autoUploadOnWiFi: settings.autoUploadOnWiFi,
        pauseOnCellular: settings.pauseOnCellular,
        cellularDataMode: settings.cellularDataMode,
        wifiDataMode: settings.wifiDataMode,
        showDataWarnings: settings.showDataWarnings,
        monthlyDataLimitMB: settings.monthlyDataLimitMB,
        mobileTargetMbps: settings.mobileTargetMbps,
      );
    });
  }

  Future<void> _updateNetworkSettings({
    bool? pauseOnCellular,
    DataUsageMode? cellularDataMode,
    DataUsageMode? wifiDataMode,
  }) async {
    final next = NetworkSettings(
      autoUploadOnWiFi: _networkSettings.autoUploadOnWiFi,
      pauseOnCellular: pauseOnCellular ?? _networkSettings.pauseOnCellular,
      cellularDataMode: cellularDataMode ?? _networkSettings.cellularDataMode,
      wifiDataMode: wifiDataMode ?? _networkSettings.wifiDataMode,
      showDataWarnings: _networkSettings.showDataWarnings,
      monthlyDataLimitMB: _networkSettings.monthlyDataLimitMB,
      mobileTargetMbps: _networkSettings.mobileTargetMbps,
    );

    final networkService = NetworkAwarenessService.maybeFind();
    if (networkService != null) {
      await networkService.updateSettings(next);
    }

    _updatePermissionsViewState(() => _networkSettings = next);
  }

  Widget _buildModeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.black : Colors.black26,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontSize: 12,
              fontFamily: 'MontserratMedium',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataModeSelector({
    required String title,
    required String description,
    required DataUsageMode value,
    required ValueChanged<DataUsageMode> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontFamily: 'MontserratSemiBold',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontFamily: 'MontserratMedium',
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildModeButton(
                label: DataUsageMode.low.label,
                selected: value == DataUsageMode.low,
                onTap: () => onChanged(DataUsageMode.low),
              ),
              const SizedBox(width: 8),
              _buildModeButton(
                label: DataUsageMode.normal.label,
                selected: value == DataUsageMode.normal,
                onTap: () => onChanged(DataUsageMode.normal),
              ),
              const SizedBox(width: 8),
              _buildModeButton(
                label: DataUsageMode.high.label,
                selected: value == DataUsageMode.high,
                onTap: () => onChanged(DataUsageMode.high),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackPolicyCard() {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'permissions.playback.title'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontFamily: 'MontserratSemiBold',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'permissions.playback.help'.tr,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              fontFamily: 'MontserratMedium',
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'permissions.playback.limit_cellular'.tr,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'MontserratSemiBold',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'permissions.playback.limit_cellular_desc'.tr,
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                        fontFamily: 'MontserratMedium',
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: _networkSettings.pauseOnCellular,
                onChanged: (value) =>
                    _updateNetworkSettings(pauseOnCellular: value),
              ),
            ],
          ),
          _buildDataModeSelector(
            title: 'permissions.playback.cellular_mode'.tr,
            description: 'permissions.playback.cellular_mode_desc'.tr,
            value: _networkSettings.cellularDataMode,
            onChanged: (value) =>
                _updateNetworkSettings(cellularDataMode: value),
          ),
          _buildDataModeSelector(
            title: 'permissions.playback.wifi_mode'.tr,
            description: 'permissions.playback.wifi_mode_desc'.tr,
            value: _networkSettings.wifiDataMode,
            onChanged: (value) => _updateNetworkSettings(wifiDataMode: value),
          ),
        ],
      ),
    );
  }
}
