import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';

void main() {
  test('network settings parses persisted query-string values safely', () {
    final settings = NetworkSettings.fromJson({
      'autoUploadOnWiFi': 'false',
      'pauseOnCellular': 'true',
      'cellularDataMode': 'normal',
      'wifiDataMode': 'low',
      'showDataWarnings': 'false',
      'monthlyDataLimitMB': '2048',
      'mobileTargetMbps': '7.5',
    });

    expect(settings.autoUploadOnWiFi, isFalse);
    expect(settings.pauseOnCellular, isTrue);
    expect(settings.cellularDataMode, DataUsageMode.normal);
    expect(settings.wifiDataMode, DataUsageMode.low);
    expect(settings.showDataWarnings, isFalse);
    expect(settings.monthlyDataLimitMB, 2048);
    expect(settings.mobileTargetMbps, 7.5);
  });

  test('network settings keeps safe defaults for malformed values', () {
    final settings = NetworkSettings.fromJson({
      'autoUploadOnWiFi': 'maybe',
      'pauseOnCellular': '??',
      'cellularDataMode': 'unknown',
      'wifiDataMode': 'unknown',
      'showDataWarnings': null,
      'monthlyDataLimitMB': 'invalid',
      'mobileTargetMbps': 'invalid',
    });

    expect(settings.autoUploadOnWiFi, isTrue);
    expect(settings.pauseOnCellular, isFalse);
    expect(settings.cellularDataMode, DataUsageMode.low);
    expect(settings.wifiDataMode, DataUsageMode.high);
    expect(settings.showDataWarnings, isTrue);
    expect(settings.monthlyDataLimitMB, 1024);
    expect(settings.mobileTargetMbps, 5.0);
  });
}
