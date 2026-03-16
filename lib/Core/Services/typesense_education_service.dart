import 'package:cloud_functions/cloud_functions.dart';

enum EducationTypesenseEntity {
  scholarship,
  practiceExam,
  answerKey,
  tutoring,
  job,
  workout,
  pastQuestion,
}

extension _EntityName on EducationTypesenseEntity {
  String get apiLabel {
    switch (this) {
      case EducationTypesenseEntity.scholarship:
        return 'scholarship';
      case EducationTypesenseEntity.practiceExam:
        return 'practice_exam';
      case EducationTypesenseEntity.answerKey:
        return 'answer_key';
      case EducationTypesenseEntity.tutoring:
        return 'tutoring';
      case EducationTypesenseEntity.job:
        return 'job';
      case EducationTypesenseEntity.workout:
        return 'workout';
      case EducationTypesenseEntity.pastQuestion:
        return 'past_question';
    }
  }
}

class TypesenseEducationSearchService {
  TypesenseEducationSearchService._();

  static final TypesenseEducationSearchService instance =
      TypesenseEducationSearchService._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<EducationTypesenseSearchResult> searchHits({
    required EducationTypesenseEntity entity,
    required String query,
    int limit = 30,
    int page = 1,
  }) async {
    final normalized = query.trim();
    final callable = _functions.httpsCallable('f21_searchEducationCallable');
    final response = await callable.call(<String, dynamic>{
      'q': normalized.isEmpty ? '*' : normalized,
      'entity': entity.apiLabel,
      'limit': limit,
      'page': page,
    });
    final data = Map<String, dynamic>.from(response.data as Map? ?? {});
    final hits = ((data['hits'] as List<dynamic>?) ?? const <dynamic>[])
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .toList(growable: false);
    return EducationTypesenseSearchResult(
      hits: hits,
      found: (data['found'] as num?)?.toInt() ?? hits.length,
      page: (data['page'] as num?)?.toInt() ?? page,
      limit: (data['limit'] as num?)?.toInt() ?? limit,
    );
  }

  Future<List<String>> searchDocIds({
    required EducationTypesenseEntity entity,
    required String query,
    int limit = 30,
    int page = 1,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return [];
    final result = await searchHits(
      entity: entity,
      query: normalized,
      limit: limit,
      page: page,
    );
    final ids = <String>[];
    for (final hitMap in result.hits) {
      final docId = (hitMap['docId'] ?? hitMap['id'])?.toString().trim() ?? '';
      if (docId.isNotEmpty) ids.add(docId);
    }
    return ids;
  }
}

class EducationTypesenseSearchResult {
  const EducationTypesenseSearchResult({
    required this.hits,
    required this.found,
    required this.page,
    required this.limit,
  });

  final List<Map<String, dynamic>> hits;
  final int found;
  final int page;
  final int limit;
}
