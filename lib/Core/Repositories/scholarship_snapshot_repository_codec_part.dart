part of 'scholarship_snapshot_repository.dart';

extension ScholarshipSnapshotRepositoryCodecPart
    on ScholarshipSnapshotRepository {
  int _asInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  bool _asBool(Object? value) {
    if (value is bool) return value;
    final raw = (value ?? '').toString().trim().toLowerCase();
    return raw == 'true' || raw == '1';
  }

  Map<String, dynamic> _encodeSnapshot(ScholarshipListingSnapshot snapshot) {
    return <String, dynamic>{
      'found': snapshot.found,
      'items': snapshot.items.map(_encodeCombinedItem).toList(growable: false),
    };
  }

  ScholarshipListingSnapshot _decodeSnapshot(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
    return ScholarshipListingSnapshot(
      items: rawItems
          .whereType<Map>()
          .map(
            (raw) => _decodeCombinedItem(Map<String, dynamic>.from(raw.cast())),
          )
          .where((item) => (item['docId'] ?? '').toString().isNotEmpty)
          .toList(growable: false),
      found: _asInt(json['found']),
    );
  }

  Map<String, dynamic> _encodeCombinedItem(Map<String, dynamic> item) {
    final model = item['model'] as IndividualScholarshipsModel;
    return <String, dynamic>{
      'docId': item['docId'] ?? '',
      'type': item['type'] ?? kIndividualScholarshipType,
      'model': model.toJson(),
      'userData':
          Map<String, dynamic>.from(item['userData'] as Map? ?? const {}),
      'likesCount': item['likesCount'] ?? 0,
      'bookmarksCount': item['bookmarksCount'] ?? 0,
      'timeStamp': item['timeStamp'] ?? model.timeStamp,
      'isSummary': item['isSummary'] ?? false,
    };
  }

  Map<String, dynamic> _decodeCombinedItem(Map<String, dynamic> item) {
    final modelMap =
        Map<String, dynamic>.from(item['model'] as Map? ?? const {});
    return <String, dynamic>{
      'model': IndividualScholarshipsModel.fromJson(modelMap),
      'type': (item['type'] ?? kIndividualScholarshipType).toString(),
      'userData':
          Map<String, dynamic>.from(item['userData'] as Map? ?? const {}),
      'docId': (item['docId'] ?? '').toString(),
      'likesCount': _asInt(item['likesCount']),
      'bookmarksCount': _asInt(item['bookmarksCount']),
      'timeStamp': _asInt(item['timeStamp']),
      'isSummary': _asBool(item['isSummary']),
    };
  }
}
