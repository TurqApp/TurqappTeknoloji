part of 'qa_lab_recorder.dart';

Map<String, dynamic> _qaLabCloneDeviceInfoMap(Map<String, dynamic> source) {
  return source.map(
    (key, value) => MapEntry(key, _qaLabCloneDeviceInfoValue(value)),
  );
}

dynamic _qaLabCloneDeviceInfoValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) =>
          MapEntry(key.toString(), _qaLabCloneDeviceInfoValue(nestedValue)),
    );
  }
  if (value is List) {
    return value.map(_qaLabCloneDeviceInfoValue).toList(growable: false);
  }
  return value;
}

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
    return _qaLabCloneDeviceInfoMap(recorder._cachedExtendedDeviceInfo!);
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
  recorder._cachedExtendedDeviceInfo = _qaLabCloneDeviceInfoMap(snapshot);
  return _qaLabCloneDeviceInfoMap(snapshot);
}

Future<Map<String, dynamic>> _qaLabGetCachedExtendedDeviceInfo(
  QALabRecorder recorder,
) {
  final cached = recorder._cachedExtendedDeviceInfo;
  if (cached != null) {
    return Future<Map<String, dynamic>>.value(
      _qaLabCloneDeviceInfoMap(cached),
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
