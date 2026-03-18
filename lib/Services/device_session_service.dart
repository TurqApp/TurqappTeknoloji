import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class DeviceSessionService {
  DeviceSessionService._();

  static final DeviceSessionService instance = DeviceSessionService._();

  static const String _deviceKeyPref = 'device_session.device_key';

  Future<String> getOrCreateDeviceKey() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = (prefs.getString(_deviceKeyPref) ?? '').trim();
    if (existing.isNotEmpty) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final buffer = StringBuffer(
      DateTime.now().millisecondsSinceEpoch.toRadixString(16),
    );
    for (final byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    final generated = buffer.toString();
    await prefs.setString(_deviceKeyPref, generated);
    return generated;
  }
}
