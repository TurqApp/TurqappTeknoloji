part of 'network_awareness_service.dart';

extension NetworkAwarenessServiceStoragePart on NetworkAwarenessService {
  Future<void> trackDataUsage({
    required int uploadMB,
    int downloadMB = 0,
  }) async {
    final now = DateTime.now();
    final lastReset = dataUsage.lastReset;

    final isWifiNow = isOnWiFi;
    final isCellularNow = isOnCellular;

    if (now.month != lastReset.month || now.year != lastReset.year) {
      _dataUsage.value = DataUsageStats(
        uploadedMB: uploadMB,
        downloadedMB: downloadMB,
        uploadedWifiMB: isWifiNow ? uploadMB : 0,
        downloadedWifiMB: isWifiNow ? downloadMB : 0,
        uploadedCellularMB: isCellularNow ? uploadMB : 0,
        downloadedCellularMB: isCellularNow ? downloadMB : 0,
        lastReset: DateTime(now.year, now.month, 1),
      );
    } else {
      _dataUsage.value = DataUsageStats(
        uploadedMB: dataUsage.uploadedMB + uploadMB,
        downloadedMB: dataUsage.downloadedMB + downloadMB,
        uploadedWifiMB: dataUsage.uploadedWifiMB + (isWifiNow ? uploadMB : 0),
        downloadedWifiMB:
            dataUsage.downloadedWifiMB + (isWifiNow ? downloadMB : 0),
        uploadedCellularMB:
            dataUsage.uploadedCellularMB + (isCellularNow ? uploadMB : 0),
        downloadedCellularMB:
            dataUsage.downloadedCellularMB + (isCellularNow ? downloadMB : 0),
        lastReset: dataUsage.lastReset,
      );
    }

    await _saveDataUsage();
  }

  Future<void> updateSettings(NetworkSettings newSettings) async {
    _settings.value = newSettings;
    await _saveSettings();
  }

  Future<void> resetDataUsage() async {
    _dataUsage.value = DataUsageStats(
      uploadedMB: 0,
      downloadedMB: 0,
      uploadedWifiMB: 0,
      downloadedWifiMB: 0,
      uploadedCellularMB: 0,
      downloadedCellularMB: 0,
      lastReset: DateTime.now(),
    );
    await _saveDataUsage();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString(_networkAwarenessSettingsKey);

    if (settingsString != null) {
      try {
        final settingsJson = Map<String, dynamic>.from(
          Uri.splitQueryString(settingsString),
        );
        _settings.value = NetworkSettings.fromJson(settingsJson);
      } catch (_) {
        await prefs.remove(_networkAwarenessSettingsKey);
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = Uri(
      queryParameters: _settings.value
          .toJson()
          .map((key, value) => MapEntry(key, value.toString())),
    ).query;
    await prefs.setString(_networkAwarenessSettingsKey, settingsString);
  }

  Future<void> _loadDataUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final dataUsageString = prefs.getString(_networkAwarenessDataUsageKey);

    if (dataUsageString != null) {
      try {
        final dataUsageJson = Map<String, dynamic>.from(
          Uri.splitQueryString(dataUsageString),
        );
        _dataUsage.value = DataUsageStats.fromJson(dataUsageJson);
      } catch (_) {
        await prefs.remove(_networkAwarenessDataUsageKey);
      }
    }
  }

  Future<void> _saveDataUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final dataUsageString = Uri(
      queryParameters: _dataUsage.value
          .toJson()
          .map((key, value) => MapEntry(key, value.toString())),
    ).query;
    await prefs.setString(
      _networkAwarenessDataUsageKey,
      dataUsageString,
    );
  }
}
