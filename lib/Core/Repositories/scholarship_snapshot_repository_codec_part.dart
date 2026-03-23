part of 'scholarship_snapshot_repository.dart';

extension ScholarshipSnapshotRepositoryCodecPart
    on ScholarshipSnapshotRepository {
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
      found: (json['found'] as num?)?.toInt() ?? 0,
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
      'likesCount': (item['likesCount'] as num?)?.toInt() ?? 0,
      'bookmarksCount': (item['bookmarksCount'] as num?)?.toInt() ?? 0,
      'timeStamp': (item['timeStamp'] as num?)?.toInt() ?? 0,
      'isSummary': item['isSummary'] == true,
    };
  }
}
