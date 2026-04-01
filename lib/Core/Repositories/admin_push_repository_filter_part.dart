part of 'admin_push_repository.dart';

extension AdminPushRepositoryFilterPart on AdminPushRepository {
  int? _parseEpochMillis(String raw) {
    final asInt = int.tryParse(raw);
    if (asInt == null) return null;
    return raw.length >= 13 ? asInt : asInt * 1000;
  }

  bool _asBoolFlag(dynamic raw, {bool fallback = false}) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final normalized = raw.trim().toLowerCase();
      if (normalized.isEmpty) return fallback;
      switch (normalized) {
        case 'true':
        case '1':
        case 'yes':
        case 'y':
        case 'on':
          return true;
        case 'false':
        case '0':
        case 'no':
        case 'n':
        case 'off':
          return false;
      }
    }
    return fallback;
  }

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
    return _asBoolFlag(data['isDeleted']) ||
        statusLc == 'deleted' ||
        statusLc == 'pending_deletion';
  }

  bool _isBannedImpl(Map<String, dynamic> data) {
    return _asBoolFlag(data['isBanned']) || _asBoolFlag(data['ban']);
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
    final asMillis = _parseEpochMillis(raw);
    if (asMillis != null) {
      try {
        birthDate = DateTime.fromMillisecondsSinceEpoch(asMillis);
      } catch (_) {
        birthDate = null;
      }
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
    if (birthDate == null || birthDate.year < 1900) return null;
    if (birthDate.isAfter(DateTime.now())) return null;

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
