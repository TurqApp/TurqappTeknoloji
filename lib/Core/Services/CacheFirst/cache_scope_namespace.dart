import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Localization/app_language_service.dart';

class CacheScopeNamespace {
  const CacheScopeNamespace._();

  static const String guestActorId = 'guest';
  static const String _defaultLocaleCode = 'tr_TR';
  static const String _defaultScopeTag = 'default';

  static String buildQueryScope({
    required String userId,
    required int limit,
    required String scopeTag,
    required int schemaVersion,
    Map<String, Object?> qualifiers = const <String, Object?>{},
    String? localeCode,
  }) {
    final normalizedEntries = qualifiers.entries
        .map(
          (entry) => MapEntry(
            entry.key.trim(),
            (entry.value ?? '').toString().trim(),
          ),
        )
        .where(
          (entry) => entry.key.isNotEmpty && entry.value.isNotEmpty,
        )
        .toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));

    final segments = <String>[
      'actor=${_normalizeActorId(userId)}',
      'locale=${_normalizeLocaleCode(localeCode)}',
      'schema=v${schemaVersion < 1 ? 1 : schemaVersion}',
      'scope=${_normalizeScopeTag(scopeTag)}',
      'limit=${limit < 0 ? 0 : limit}',
      for (final entry in normalizedEntries) '${entry.key}=${entry.value}',
    ];

    return segments.join('|');
  }

  static String buildAssetScope({
    required String videoId,
    required String rendition,
    required String mediaVersion,
    String visibilityClass = 'public',
  }) {
    final normalizedVideoId = videoId.trim();
    final normalizedRendition = rendition.trim();
    final normalizedVersion = mediaVersion.trim();
    final normalizedVisibility =
        visibilityClass.trim().isEmpty ? 'public' : visibilityClass.trim();

    return <String>[
      'video=${normalizedVideoId.isEmpty ? 'unknown' : normalizedVideoId}',
      'rendition=${normalizedRendition.isEmpty ? 'default' : normalizedRendition}',
      'version=${normalizedVersion.isEmpty ? 'v1' : normalizedVersion}',
      'visibility=$normalizedVisibility',
    ].join('|');
  }

  static String _normalizeActorId(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) return guestActorId;
    return normalized;
  }

  static String _normalizeScopeTag(String scopeTag) {
    final normalized = scopeTag.trim();
    if (normalized.isEmpty) return _defaultScopeTag;
    return normalized;
  }

  static String _normalizeLocaleCode(String? localeCode) {
    final explicit = _normalizeLocaleCodeString(localeCode);
    if (explicit.isNotEmpty) return explicit;

    final languageService = maybeFindAppLanguageService();
    final serviceLocale =
        _normalizeLocaleCodeString(languageService?.currentCode);
    if (serviceLocale.isNotEmpty) return serviceLocale;

    final appLocale = _localeToCode(Get.locale);
    if (appLocale.isNotEmpty) return appLocale;

    final deviceLocale = _localeToCode(Get.deviceLocale);
    if (deviceLocale.isNotEmpty) return deviceLocale;

    return _defaultLocaleCode;
  }

  static String _normalizeLocaleCodeString(String? value) {
    final normalized = value?.trim().replaceAll('-', '_') ?? '';
    if (normalized.isEmpty) return '';
    return normalized;
  }

  static String _localeToCode(Locale? locale) {
    if (locale == null) return '';
    final languageCode = locale.languageCode.trim();
    if (languageCode.isEmpty) return '';
    final countryCode = locale.countryCode?.trim() ?? '';
    if (countryCode.isEmpty) return languageCode;
    return '${languageCode}_$countryCode';
  }
}
