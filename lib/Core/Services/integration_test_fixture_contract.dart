import 'dart:convert';

class IntegrationTestFixtureSurface {
  static List<String> _cloneDocIds(Iterable<dynamic> source) {
    return source
        .map((item) => item?.toString().trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
  }

  static int? _asNullableInt(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  IntegrationTestFixtureSurface({
    this.minCount,
    List<String> requiredDocIds = const <String>[],
    this.maxUnread,
  }) : requiredDocIds = _cloneDocIds(requiredDocIds);

  final int? minCount;
  final List<String> requiredDocIds;
  final int? maxUnread;

  bool get isConfigured =>
      minCount != null || requiredDocIds.isNotEmpty || maxUnread != null;

  static IntegrationTestFixtureSurface fromMap(Map<String, dynamic> raw) {
    final rawDocIds = raw['docIds'];
    return IntegrationTestFixtureSurface(
      minCount: _asNullableInt(raw['minCount']),
      requiredDocIds:
          rawDocIds is List ? _cloneDocIds(rawDocIds) : const <String>[],
      maxUnread: _asNullableInt(raw['maxUnread']),
    );
  }
}

class IntegrationTestFixtureContract {
  static Map<String, IntegrationTestFixtureSurface> _cloneSurfaces(
    Map<String, IntegrationTestFixtureSurface> source,
  ) {
    return Map<String, IntegrationTestFixtureSurface>.from(source);
  }

  IntegrationTestFixtureContract({
    Map<String, IntegrationTestFixtureSurface> surfaces =
        const <String, IntegrationTestFixtureSurface>{},
  }) : surfaces = _cloneSurfaces(surfaces);

  final Map<String, IntegrationTestFixtureSurface> surfaces;

  static final IntegrationTestFixtureContract current = fromRaw(
    const String.fromEnvironment('INTEGRATION_FIXTURE_JSON'),
  );

  bool get isConfigured => surfaces.isNotEmpty;

  IntegrationTestFixtureSurface? surface(String name) => surfaces[name];

  static IntegrationTestFixtureContract fromRaw(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return IntegrationTestFixtureContract();
    }

    try {
      final decoded = jsonDecode(normalized);
      if (decoded is! Map) {
        return IntegrationTestFixtureContract();
      }

      final parsed = <String, IntegrationTestFixtureSurface>{};
      for (final entry in decoded.entries) {
        final key = entry.key.toString().trim();
        final value = entry.value;
        if (key.isEmpty || value is! Map) continue;
        final surface = IntegrationTestFixtureSurface.fromMap(
          Map<String, dynamic>.from(value.cast<dynamic, dynamic>()),
        );
        if (!surface.isConfigured) continue;
        parsed[key] = surface;
      }
      return IntegrationTestFixtureContract(surfaces: parsed);
    } catch (_) {
      return IntegrationTestFixtureContract();
    }
  }
}
