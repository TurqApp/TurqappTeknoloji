part of 'qa_lab_recorder.dart';

Map<String, dynamic> _qaLabDeviceInfoSnapshot() {
  return <String, dynamic>{
    'platform': defaultTargetPlatform.name,
    'buildMode': kReleaseMode
        ? 'release'
        : kProfileMode
            ? 'profile'
            : 'debug',
  };
}

Future<Map<String, dynamic>> _qaLabBuildExtendedDeviceInfo(
  QALabRecorder recorder,
) async {
  if (recorder._cachedExtendedDeviceInfo != null) {
    return Map<String, dynamic>.from(recorder._cachedExtendedDeviceInfo!);
  }
  final packageInfo = await PackageInfo.fromPlatform();
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo =
      GetPlatform.isAndroid ? await deviceInfo.androidInfo : null;
  final iosInfo = GetPlatform.isIOS ? await deviceInfo.iosInfo : null;
  final snapshot = <String, dynamic>{
    'package': <String, dynamic>{
      'appName': packageInfo.appName,
      'packageName': packageInfo.packageName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
    },
    'device': <String, dynamic>{
      if (androidInfo != null) 'manufacturer': androidInfo.manufacturer,
      if (androidInfo != null) 'model': androidInfo.model,
      if (androidInfo != null) 'sdkInt': androidInfo.version.sdkInt,
      if (iosInfo != null) 'name': iosInfo.name,
      if (iosInfo != null) 'model': iosInfo.model,
      if (iosInfo != null) 'systemVersion': iosInfo.systemVersion,
    },
  };
  recorder._cachedExtendedDeviceInfo = snapshot;
  return Map<String, dynamic>.from(snapshot);
}

Future<Map<String, dynamic>> _qaLabGetCachedExtendedDeviceInfo(
  QALabRecorder recorder,
) {
  final cached = recorder._cachedExtendedDeviceInfo;
  if (cached != null) {
    return Future<Map<String, dynamic>>.value(
      Map<String, dynamic>.from(cached),
    );
  }
  final inFlight = recorder._extendedDeviceInfoFuture;
  if (inFlight != null) {
    return inFlight;
  }
  final future = _qaLabBuildExtendedDeviceInfo(recorder);
  recorder._extendedDeviceInfoFuture = future.whenComplete(() {
    recorder._extendedDeviceInfoFuture = null;
  });
  return recorder._extendedDeviceInfoFuture!;
}
