import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:turqappv2/Core/Services/app_cloud_functions.dart';

part 'short_link_service_upsert_part.dart';
part 'short_link_service_url_part.dart';

class ShortLinkService {
  static const String _defaultDomain = 'turqapp.com';
  static const Duration _callTimeout = Duration(milliseconds: 8000);
  static final Map<String, String> _postUrlCache = <String, String>{};
  static final Set<String> _postUrlWarmupInFlight = <String>{};
  static final Map<String, String> _storyUrlCache = <String, String>{};
  static final Set<String> _storyUrlWarmupInFlight = <String>{};
  static final Map<String, String> _eduUrlCache = <String, String>{};
  static final Set<String> _eduUrlWarmupInFlight = <String>{};
  static final Map<String, String> _jobUrlCache = <String, String>{};
  static final Set<String> _jobUrlWarmupInFlight = <String>{};
  static final Map<String, String> _marketUrlCache = <String, String>{};
  static final Set<String> _marketUrlWarmupInFlight = <String>{};
  static final Map<String, String> _internalEduUrlCache = <String, String>{};
}
