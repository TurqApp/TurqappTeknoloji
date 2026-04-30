import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';

final int _defaultStartupSurfaceOrderSeed =
    DateTime.now().millisecondsSinceEpoch;
String _defaultStartupSurfaceDeviceSalt = '';
final Map<String, int> _startupSurfaceOrderSeedByNamespace = <String, int>{};
final Map<String, String> _startupSurfaceDeviceSaltByNamespace =
    <String, String>{};
const Map<String, int> _startupSurfaceBandMinutesByNamespace = <String, int>{
  'feed': 10,
  'short': 10,
  'short_quota': 10,
};
const Map<String, int> _startupSurfaceMotorCountByNamespace = <String, int>{
  'feed': 6,
  'short': 6,
  'short_quota': 6,
};

void beginStartupSurfaceSession({
  required String sessionNamespace,
  String? deviceSalt,
  bool forceNew = false,
}) {
  final normalizedNamespace = sessionNamespace.trim();
  if (normalizedNamespace.isEmpty) return;
  final normalizedSalt = (deviceSalt ?? '').trim();
  if (normalizedSalt.isNotEmpty) {
    _startupSurfaceDeviceSaltByNamespace[normalizedNamespace] = normalizedSalt;
  }
  if (forceNew) {
    _startupSurfaceOrderSeedByNamespace[normalizedNamespace] =
        _freshStartupSurfaceSeed();
  }
}

Future<void> rotateStartupMotorSessionsOnAppLaunch({
  SharedPreferences? prefs,
  String? deviceSalt,
}) async {
  final effectivePrefs =
      prefs ?? await ensureLocalPreferenceRepository().sharedPreferences();
  final normalizedSalt = (deviceSalt ?? '').trim();
  for (final entry in _startupSurfaceMotorCountByNamespace.entries) {
    final namespace = entry.key;
    final motorCount = entry.value;
    final bandMinutes = _startupSurfaceBandMinutesByNamespace[namespace] ?? 10;
    final key = 'startup_motor_cycle_$namespace';
    final previousIndex = effectivePrefs.getInt(key) ?? -1;
    final nextIndex = (previousIndex + 1) % motorCount;
    await effectivePrefs.setInt(key, nextIndex);
    if (normalizedSalt.isNotEmpty) {
      _startupSurfaceDeviceSaltByNamespace[namespace] = normalizedSalt;
    }
    _startupSurfaceOrderSeedByNamespace[namespace] = _seedForMotorIndex(
      motorIndex: nextIndex,
      bandMinutes: bandMinutes,
    );
  }
}

int startupSurfaceSessionSeed({
  required String sessionNamespace,
}) {
  final normalizedNamespace = sessionNamespace.trim();
  if (normalizedNamespace.isEmpty) {
    return _defaultStartupSurfaceOrderSeed;
  }
  return _startupSurfaceSeedForNamespace(normalizedNamespace);
}

int startupVariantIndexForSurface({
  required String surfaceKey,
  String? sessionNamespace,
  int variantCount = 10,
}) {
  if (variantCount <= 1) return 0;
  final effectiveNamespace =
      _resolveStartupSurfaceNamespace(surfaceKey, sessionNamespace);
  return Object.hash(
        surfaceKey,
        _startupSurfaceSeedForNamespace(effectiveNamespace),
        _startupSurfaceDeviceSaltForNamespace(effectiveNamespace),
      ).abs() %
      variantCount;
}

List<T> reorderForStartupSurface<T>(
  List<T> items, {
  required String surfaceKey,
  String? sessionNamespace,
  int maxShuffleWindow = 20,
}) {
  if (items.length < 2 || maxShuffleWindow < 2) {
    return items.toList(growable: false);
  }

  final normalized = items.toList(growable: false);
  final headCount = min(maxShuffleWindow, normalized.length);
  if (headCount < 2) {
    return normalized;
  }

  final effectiveNamespace =
      _resolveStartupSurfaceNamespace(surfaceKey, sessionNamespace);
  final orderSeed = _startupSurfaceSeedForNamespace(effectiveNamespace);
  final deviceSalt = _startupSurfaceDeviceSaltForNamespace(effectiveNamespace);
  final originalHead = normalized.take(headCount).toList(growable: false);
  final shuffledHead = originalHead.toList(growable: true)
    ..shuffle(
      Random(
        Object.hash(
          surfaceKey,
          orderSeed,
          deviceSalt,
        ),
      ),
    );

  var changed = false;
  for (int i = 0; i < originalHead.length; i++) {
    if (!identical(originalHead[i], shuffledHead[i])) {
      changed = true;
      break;
    }
  }

  if (!changed) {
    final shift = (orderSeed % headCount).abs();
    final effectiveShift = shift == 0 ? 1 : shift;
    shuffledHead
      ..clear()
      ..addAll(originalHead.skip(effectiveShift))
      ..addAll(originalHead.take(effectiveShift));
  }

  return <T>[
    ...shuffledHead,
    ...normalized.skip(headCount),
  ];
}

String _resolveStartupSurfaceNamespace(
  String surfaceKey,
  String? sessionNamespace,
) {
  final normalizedNamespace = (sessionNamespace ?? '').trim();
  if (normalizedNamespace.isNotEmpty) {
    return normalizedNamespace;
  }
  final normalizedSurfaceKey = surfaceKey.trim();
  if (normalizedSurfaceKey.isNotEmpty) {
    return normalizedSurfaceKey;
  }
  return '__default__';
}

int _startupSurfaceSeedForNamespace(String namespace) {
  return _startupSurfaceOrderSeedByNamespace[namespace] ??
      _defaultStartupSurfaceOrderSeed;
}

String _startupSurfaceDeviceSaltForNamespace(String namespace) {
  return _startupSurfaceDeviceSaltByNamespace[namespace] ??
      _defaultStartupSurfaceDeviceSalt;
}

int _seedForMotorIndex({
  required int motorIndex,
  required int bandMinutes,
}) {
  final now = DateTime.now();
  final targetMinute = ((motorIndex * bandMinutes) % 60).clamp(0, 59);
  final adjusted = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour,
    targetMinute,
    now.second,
    now.millisecond,
    now.microsecond,
  );
  return adjusted.millisecondsSinceEpoch;
}

int _freshStartupSurfaceSeed() {
  return DateTime.now().microsecondsSinceEpoch;
}
