import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalPreferenceRepository extends GetxService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> _store() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> sharedPreferences() => _store();

  Future<int?> getInt(String key) async {
    final prefs = await _store();
    return prefs.getInt(key);
  }

  Future<bool?> getBool(String key) async {
    final prefs = await _store();
    return prefs.getBool(key);
  }

  Future<String?> getString(String key) async {
    final prefs = await _store();
    return prefs.getString(key);
  }

  Future<List<String>?> getStringList(String key) async {
    final prefs = await _store();
    return prefs.getStringList(key);
  }

  Future<void> setString(String key, String value) async {
    final prefs = await _store();
    await prefs.setString(key, value);
  }

  Future<void> setStringList(String key, List<String> value) async {
    final prefs = await _store();
    await prefs.setStringList(key, value);
  }

  Future<void> setInt(String key, int value) async {
    final prefs = await _store();
    await prefs.setInt(key, value);
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await _store();
    await prefs.setBool(key, value);
  }

  Future<void> remove(String key) async {
    final prefs = await _store();
    await prefs.remove(key);
  }
}

LocalPreferenceRepository? maybeFindLocalPreferenceRepository() {
  if (!Get.isRegistered<LocalPreferenceRepository>()) return null;
  return Get.find<LocalPreferenceRepository>();
}

LocalPreferenceRepository ensureLocalPreferenceRepository() {
  return maybeFindLocalPreferenceRepository() ??
      Get.put(LocalPreferenceRepository(), permanent: true);
}
