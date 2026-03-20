import 'dart:convert';

class IntegrationTestFixtureSurface {
  const IntegrationTestFixtureSurface({
    this.minCount,
    this.requiredDocIds = const <String>[],
    this.maxUnread,
  });

  final int? minCount;
  final List<String> requiredDocIds;
  final int? maxUnread;

  bool get isConfigured =>
      minCount != null || requiredDocIds.isNotEmpty || maxUnread != null;

  static IntegrationTestFixtureSurface fromMap(Map<String, dynamic> raw) {
    final rawDocIds = raw['docIds'];
    return IntegrationTestFixtureSurface(
      minCount: (raw['minCount'] as num?)?.toInt(),
      requiredDocIds: rawDocIds is List
          ? rawDocIds
              .map((item) => item?.toString().trim() ?? '')
              .where((id) => id.isNotEmpty)
              .toList(growable: false)
          : const <String>[],
      maxUnread: (raw['maxUnread'] as num?)?.toInt(),
    );
  }
}

class IntegrationTestFixtureContract {
  const IntegrationTestFixtureContract({
    this.surfaces = const <String, IntegrationTestFixtureSurface>{},
  });

  final Map<String, IntegrationTestFixtureSurface> surfaces;

  static final IntegrationTestFixtureContract current = fromRaw(
    const String.fromEnvironment('INTEGRATION_FIXTURE_JSON'),
  );

  bool get isConfigured => surfaces.isNotEmpty;

  IntegrationTestFixtureSurface? surface(String name) => surfaces[name];

  static IntegrationTestFixtureContract fromRaw(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      return const IntegrationTestFixtureContract();
    }

    try {
      final decoded = jsonDecode(normalized);
      if (decoded is! Map) {
        return const IntegrationTestFixtureContract();
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
      return const IntegrationTestFixtureContract();
    }
  }
}
