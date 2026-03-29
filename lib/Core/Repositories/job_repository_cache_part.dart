part of 'job_repository.dart';

extension JobRepositoryCacheX on JobRepository {
  Future<void> clearAll() async {
    _memory.clear();
    _boolMemory.clear();
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith(JobRepository._prefsPrefix))
        .toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  List<JobModel>? _getFromMemory(String key) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > JobRepository._ttl) {
      _memory.remove(key);
      return null;
    }
    return _cloneJobs(entry.items);
  }

  Future<_TimedJobs?> _getFromPrefsEntry(String key) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final prefsKey = '${JobRepository._prefsPrefix}::$key';
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedRaw = jsonDecode(raw);
      if (decodedRaw is! Map) {
        await prefs.remove(prefsKey);
        return null;
      }
      final decoded = Map<String, dynamic>.from(
        decodedRaw.cast<dynamic, dynamic>(),
      );
      final cachedAt = DateTime.tryParse(decoded['cachedAt'] as String? ?? '');
      if (cachedAt == null ||
          DateTime.now().difference(cachedAt) > JobRepository._ttl) {
        await prefs.remove(prefsKey);
        return null;
      }
      final items =
          (decoded['items'] as List<dynamic>? ?? const <dynamic>[]).map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return JobModel.fromMap(
          Map<String, dynamic>.from(map['data'] as Map),
          map['docID'] as String? ?? '',
        );
      }).toList(growable: false);
      return _TimedJobs(items: items, cachedAt: cachedAt);
    } catch (_) {
      await prefs.remove(prefsKey);
      return null;
    }
  }

  Future<void> _store(String key, List<JobModel> items) async {
    _memory[key] = _TimedJobs(
      items: _cloneJobs(items),
      cachedAt: DateTime.now(),
    );
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final payload = jsonEncode(<String, dynamic>{
      'cachedAt': DateTime.now().toIso8601String(),
      'items': items
          .map((item) => <String, dynamic>{
                'docID': item.docID,
                'data': item.toMap(),
              })
          .toList(growable: false),
    });
    await prefs.setString('${JobRepository._prefsPrefix}::$key', payload);
  }

  Future<List<Map<String, dynamic>>?> _readList(String key) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final prefsKey = '${JobRepository._prefsPrefix}::$key';
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedRaw = jsonDecode(raw);
      if (decodedRaw is! Map) {
        await prefs.remove(prefsKey);
        return null;
      }
      final decoded = Map<String, dynamic>.from(
        decodedRaw.cast<dynamic, dynamic>(),
      );
      final cachedAt = DateTime.tryParse(decoded['cachedAt'] as String? ?? '');
      if (cachedAt == null ||
          DateTime.now().difference(cachedAt) > JobRepository._ttl) {
        await prefs.remove(prefsKey);
        return null;
      }
      return (decoded['items'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
    } catch (_) {
      await prefs.remove(prefsKey);
      return null;
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> items) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(
      '${JobRepository._prefsPrefix}::$key',
      jsonEncode(<String, dynamic>{
        'cachedAt': DateTime.now().toIso8601String(),
        'items': items,
      }),
    );
  }

  Future<void> _invalidateListCache(String key) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.remove('${JobRepository._prefsPrefix}::$key');
  }

  String _statusBody(String status, String title, String companyName) {
    final displayTitle = title.isNotEmpty
        ? title
        : companyName.isNotEmpty
            ? companyName
            : 'ilan';
    switch (status) {
      case 'accepted':
        return '$displayTitle başvurun kabul edildi.';
      case 'reviewing':
        return '$displayTitle başvurun incelemeye alındı.';
      case 'rejected':
        return '$displayTitle başvurun reddedildi.';
      default:
        return '$displayTitle başvuru durumun güncellendi.';
    }
  }

  List<List<String>> _chunkIds(List<String> input, int size) {
    if (input.isEmpty) return const <List<String>>[];
    final chunks = <List<String>>[];
    for (var i = 0; i < input.length; i += size) {
      final end = (i + size > input.length) ? input.length : i + size;
      chunks.add(input.sublist(i, end));
    }
    return chunks;
  }

  List<JobModel> _cloneJobs(List<JobModel> items) {
    return items.map(_cloneJob).toList(growable: false);
  }

  JobModel _cloneJob(JobModel item) {
    return JobModel(
      docID: item.docID,
      brand: item.brand,
      calismaGunleri: List<String>.from(item.calismaGunleri),
      calismaSaatiBaslangic: item.calismaSaatiBaslangic,
      calismaSaatiBitis: item.calismaSaatiBitis,
      calismaTuru: List<String>.from(item.calismaTuru),
      ended: item.ended,
      isTanimi: item.isTanimi,
      lat: item.lat,
      long: item.long,
      adres: item.adres,
      logo: item.logo,
      maas1: item.maas1,
      maas2: item.maas2,
      meslek: item.meslek,
      timeStamp: item.timeStamp,
      userID: item.userID,
      yanHaklar: List<String>.from(item.yanHaklar),
      city: item.city,
      town: item.town,
      kacKm: item.kacKm,
      about: item.about,
      ilanBasligi: item.ilanBasligi,
      deneyimSeviyesi: item.deneyimSeviyesi,
      basvuruSayisi: item.basvuruSayisi,
      pozisyonSayisi: item.pozisyonSayisi,
      viewCount: item.viewCount,
      applicationCount: item.applicationCount,
      endedAt: item.endedAt,
      authorAvatarUrl: item.authorAvatarUrl,
      authorDisplayName: item.authorDisplayName,
      authorNickname: item.authorNickname,
      shortId: item.shortId,
      shortUrl: item.shortUrl,
      rozet: item.rozet,
    );
  }
}
