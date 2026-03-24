part of 'admin_push_repository.dart';

extension AdminPushRepositoryFilterPart on AdminPushRepository {
  bool _hasPushTokenImpl(Map<String, dynamic> data) {
    final candidates = <Object?>[
      data['fcmToken'],
      data['pushToken'],
      data['token'],
      data['fcm_token'],
    ];
    for (final candidate in candidates) {
      final normalized = (candidate ?? '').toString().trim();
      if (normalized.isNotEmpty) return true;
    }
    return false;
  }

  bool _isDeletedOrInactiveImpl(Map<String, dynamic> data) {
    final accountStatus = (data['accountStatus'] ?? '').toString().trim();
    final statusLc = accountStatus.toLowerCase();
    return data['isDeleted'] == true ||
        statusLc == 'deleted' ||
        statusLc == 'pending_deletion';
  }

  bool _isBannedImpl(Map<String, dynamic> data) {
    return data['isBanned'] == true || data['ban'] == true;
  }

  List<String> _collectLocationValuesImpl(Map<String, dynamic> data) {
    final values = <String>[];
    for (final key in const <String>[
      'city',
      'il',
      'ilce',
      'locationSehir',
      'ikametSehir',
    ]) {
      final value = normalizeSearchText((data[key] ?? '').toString());
      if (value.isNotEmpty) values.add(value);
    }
    return values;
  }

  int? _extractAgeImpl(Map<String, dynamic> data) {
    final raw = (data['dogumTarihi'] ?? '').toString().trim();
    if (raw.isEmpty) return null;

    DateTime? birthDate;
    final asInt = int.tryParse(raw);
    if (asInt != null) {
      final ms = raw.length >= 13 ? asInt : asInt * 1000;
      birthDate = DateTime.fromMillisecondsSinceEpoch(ms);
    } else {
      birthDate = DateTime.tryParse(raw);
      if (birthDate == null && raw.contains('/')) {
        final parts = raw.split('/');
        if (parts.length == 3) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (d != null && m != null && y != null) {
            birthDate = DateTime(y, m, d);
          }
        }
      }
    }
    if (birthDate == null) return null;

    final now = DateTime.now();
    var age = now.year - birthDate.year;
    final hadBirthday = (now.month > birthDate.month) ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hadBirthday) age--;
    return age < 0 ? null : age;
  }

  bool _isEligiblePushTargetImpl(String userId, Map<String, dynamic> data) {
    return userId.trim().isNotEmpty &&
        !_isDeletedOrInactiveImpl(data) &&
        !_isBannedImpl(data) &&
        _hasPushTokenImpl(data);
  }
}
