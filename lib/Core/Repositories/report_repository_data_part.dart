part of 'report_repository.dart';

class ReportAggregateItem {
  final String id;
  final Map<String, dynamic> data;

  ReportAggregateItem({
    required this.id,
    required Map<String, dynamic> data,
  }) : data = _cloneReportDataMap(data);
}

class ReportReasonItem {
  final String id;
  final Map<String, dynamic> data;

  ReportReasonItem({
    required this.id,
    required Map<String, dynamic> data,
  }) : data = _cloneReportDataMap(data);
}

extension ReportRepositoryDataPart on ReportRepository {
  Stream<List<ReportAggregateItem>> watchAggregates({int limit = 100}) {
    return FirebaseFirestore.instance
        .collection('reportAggregates')
        .orderBy('lastReportAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => ReportAggregateItem(
                  id: doc.id,
                  data: _cloneReportDataMap(doc.data()),
                ),
              )
              .toList(growable: false),
        );
  }

  Stream<List<ReportReasonItem>> watchReasonsForTarget(
    String targetKey, {
    int limit = 20,
  }) {
    return FirebaseFirestore.instance
        .collection('reportAggregates')
        .doc(targetKey)
        .collection('reasons')
        .orderBy('count', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map(
            (doc) => ReportReasonItem(
              id: doc.id,
              data: _cloneReportDataMap(doc.data()),
            ),
          )
          .toList(growable: false);
      items.sort(
        (a, b) => _reportAsInt(b.data['count'])
            .compareTo(_reportAsInt(a.data['count'])),
      );
      return items;
    });
  }

  Future<Map<String, dynamic>> ensureConfigWithCallable() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
        .httpsCallable('ensureReportsConfig');
    final res = await callable.call(<String, dynamic>{
      if (uid.isNotEmpty) 'uid': uid,
    });
    final data = res.data;
    if (data is Map && data['config'] is Map) {
      return _cloneReportDataMap(
        (data['config'] as Map).map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      );
    }
    return const <String, dynamic>{};
  }

  Future<void> reviewAggregate({
    required String aggregateId,
    required bool restore,
  }) async {
    final uid = CurrentUserService.instance.effectiveUserId;
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west3')
        .httpsCallable('reviewReportedTarget');
    await callable.call(<String, dynamic>{
      'aggregateId': aggregateId,
      'action': restore ? 'restore' : 'keep_hidden',
      if (uid.isNotEmpty) 'uid': uid,
    });
  }

  Future<List<ReportModel>> fetchSelections() async {
    try {
      final snap = await FirebaseFirestore.instance
          .doc('adminConfig/reports')
          .get(const GetOptions(source: Source.serverAndCache));
      final data = snap.data();
      if (data == null) return reportSelections;
      final rawCategories = data['categories'];
      if (rawCategories is! Map) return reportSelections;

      final items = <ReportModel>[];
      for (final entry in rawCategories.entries) {
        final key = entry.key.toString().trim();
        final raw = entry.value;
        if (key.isEmpty || raw is! Map) continue;
        final category = _cloneReportDataMap(
          raw.map((mapKey, value) => MapEntry(mapKey.toString(), value)),
        );
        if (category['enabled'] == false) continue;
        final title = (category['title'] ?? '').toString().trim();
        if (title.isEmpty) continue;
        items.add(
          ReportModel(
            key: key,
            title: title,
            description: (category['description'] ?? title).toString().trim(),
          ),
        );
      }

      if (items.isEmpty) return reportSelections;
      items.sort((a, b) => a.title.compareTo(b.title));
      return items;
    } catch (_) {
      return reportSelections;
    }
  }
}

Map<String, dynamic> _cloneReportDataMap(Map<String, dynamic> source) {
  return source.map(
    (key, value) => MapEntry(key, _cloneReportDataValue(value)),
  );
}

dynamic _cloneReportDataValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key.toString(),
        _cloneReportDataValue(nestedValue),
      ),
    );
  }
  if (value is List) {
    return value.map(_cloneReportDataValue).toList(growable: false);
  }
  return value;
}

int _reportAsInt(dynamic raw) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}
