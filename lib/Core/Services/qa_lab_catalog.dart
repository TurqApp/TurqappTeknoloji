enum QALabTestOrigin {
  integration,
  suite,
  unit,
  widget,
  backend,
}

class QALabSurfaceCoverageReport {
  const QALabSurfaceCoverageReport({
    required this.surface,
    required this.requiredTags,
    required this.coveredTags,
    required this.missingTags,
    required this.integrationCount,
    required this.runnableInAppCount,
    required this.suiteCount,
    required this.unitCount,
    required this.widgetCount,
    required this.backendCount,
  });

  final String surface;
  final List<String> requiredTags;
  final List<String> coveredTags;
  final List<String> missingTags;
  final int integrationCount;
  final int runnableInAppCount;
  final int suiteCount;
  final int unitCount;
  final int widgetCount;
  final int backendCount;

  double get coverageRatio {
    if (requiredTags.isEmpty) return 1;
    return coveredTags.length / requiredTags.length;
  }

  bool get complete => missingTags.isEmpty;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'surface': surface,
      'requiredTags': requiredTags,
      'coveredTags': coveredTags,
      'missingTags': missingTags,
      'integrationCount': integrationCount,
      'runnableInAppCount': runnableInAppCount,
      'suiteCount': suiteCount,
      'unitCount': unitCount,
      'widgetCount': widgetCount,
      'backendCount': backendCount,
      'coverageRatio': coverageRatio,
      'complete': complete,
    };
  }
}

class QALabCatalogEntry {
  const QALabCatalogEntry({
    required this.path,
    required this.origin,
    required this.runnableInApp,
    this.notes = '',
  });

  final String path;
  final QALabTestOrigin origin;
  final bool runnableInApp;
  final String notes;

  String get id => path.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');

  String get title {
    final normalized = path.split('/').last.trim();
    if (normalized.isEmpty) return path;
    return normalized;
  }

  List<String> get tags => QALabCatalog.inferTags(path);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'path': path,
      'origin': origin.name,
      'runnableInApp': runnableInApp,
      'tags': tags,
      'notes': notes,
    };
  }
}

class QALabCatalog {
  const QALabCatalog._();

  static const List<String> focusSurfaces = <String>[
    'feed',
    'short',
    'chat',
    'notifications',
    'auth',
    'story',
    'pasaj',
    'explore',
    'profile',
    'settings',
    'permissions',
    'upload',
  ];

  static const Map<String, List<String>> focusSurfaceRequirements =
      <String, List<String>>{
    'feed': <String>[
      'feed',
      'video',
      'autoplay',
      'playback',
      'hls',
      'scroll',
      'audio',
      'network',
      'resume',
    ],
    'short': <String>[
      'short',
      'video',
      'playback',
      'scroll',
      'audio',
      'resume',
    ],
    'chat': <String>[
      'chat',
      'message',
      'upload',
    ],
    'notifications': <String>[
      'notifications',
      'route',
    ],
    'auth': <String>[
      'auth',
      'login',
      'splash',
    ],
    'story': <String>[
      'story',
      'video',
      'message',
    ],
    'pasaj': <String>[
      'pasaj',
      'education',
    ],
    'explore': <String>[
      'explore',
    ],
    'profile': <String>[
      'profile',
      'video',
      'resume',
    ],
    'settings': <String>[
      'settings',
    ],
    'permissions': <String>[
      'permissions',
      'settings',
    ],
    'upload': <String>[
      'upload',
      'composer',
    ],
  };

  static const List<QALabCatalogEntry> entries = <QALabCatalogEntry>[
    QALabCatalogEntry(
      path: 'integration_test/auth/auth_reauth_restore_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/auth/auth_session_churn_e2e_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/auth/auth_signout_state_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/auth/login_flow_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/chat/chat_listing_smoke_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path:
          'integration_test/chat/chat_media_picker_upload_failure_e2e_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/chat/chat_media_surfaces_smoke_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/chat/chat_send_message_e2e_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/comments/comment_like_e2e_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/comments/comment_reply_delete_e2e_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/comments/comment_root_delete_e2e_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path:
          'integration_test/comments/comment_surface_regression_e2e_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/education/education_detail_flow_e2e_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/explore/explore_preview_gate_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/feed/feed_black_flash_smoke_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/feed/feed_boot_visible_video_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/feed/feed_first_video_autoplay_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/feed/feed_first_video_playback_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/feed/feed_five_post_scroll_and_return_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/feed/feed_fullscreen_audio_smoke_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/feed/feed_long_session_15m_stress_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/feed/feed_native_exoplayer_truth_smoke_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/feed/feed_network_resilience_smoke_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/feed/feed_normal_scroll_playback_smoke_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/feed/feed_production_smoke_suite_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/feed/feed_resume_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/feed/feed_ten_video_smoke_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/feed/hls_data_usage_suite_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/feed/turqapp_audio_ownership_e2e_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/market/market_detail_flow_e2e_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path:
          'integration_test/notifications/notification_deeplink_route_e2e_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path:
          'integration_test/notifications/notifications_snapshot_mutation_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/profile/profile_feed_video_smoke_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/profile/profile_resume_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/shorts/short_first_two_playback_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/shorts/short_five_item_playback_stress_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/shorts/short_landscape_filter_smoke_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/shorts/short_refresh_preserve_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/shorts/short_ten_video_smoke_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/story/story_reply_reaction_e2e_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/system/permission_matrix_smoke_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path:
          'integration_test/system/permission_os_denied_state_smoke_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path:
          'integration_test/system/permission_os_granted_state_smoke_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/system/process_death_prepare_restore_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/system/process_death_verify_restore_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
    ),
    QALabCatalogEntry(
      path: 'integration_test/turqapp_complete_e2e_test.dart',
      origin: QALabTestOrigin.integration,
      runnableInApp: true,
      notes: 'Master end-to-end flow',
    ),
    QALabCatalogEntry(
      path: 'config/test_suites/extended_smoke.txt',
      origin: QALabTestOrigin.suite,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'config/test_suites/integration_smoke.tsv',
      origin: QALabTestOrigin.suite,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'config/test_suites/long_session_e2e.txt',
      origin: QALabTestOrigin.suite,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'config/test_suites/permission_os_matrix_e2e.txt',
      origin: QALabTestOrigin.suite,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'config/test_suites/process_death_e2e.txt',
      origin: QALabTestOrigin.suite,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'config/test_suites/product_depth_e2e.txt',
      origin: QALabTestOrigin.suite,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'config/test_suites/release_gate_e2e.txt',
      origin: QALabTestOrigin.suite,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'config/test_suites/turqapp_test_smoke.txt',
      origin: QALabTestOrigin.suite,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/models/current_user_model_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/models/stored_account_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/repositories/cache_repository_comprehensive_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/repositories/repository_cache_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/auth_api_service_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/cache_usefulness_engine_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/eviction_scoring_engine_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/feed_api_live_smoke_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/feed_api_response_smoke_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/integration_smoke_reporter_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/integration_test_fixture_contract_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/integration_test_state_probe_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/m3u8_parser_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/mock_api_service_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/network_awareness_service_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/playback_kpi_service_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/qa_lab_catalog_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/qa_lab_recorder_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/playback_signal_engine_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/prefetch_scoring_engine_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/runtime_health_exporter_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/storage_budget_manager_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/telemetry_threshold_policy_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/services/video_telemetry_service_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/state/chat_realtime_sync_policy_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/state/chat_unread_policy_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/state/settings_controller_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/utils/cdn_url_builder_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/utils/integration_key_contract_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/utils/integration_suite_registry_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/utils/notifications_invariant_logic_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/unit/utils/runtime_invariant_guard_test.dart',
      origin: QALabTestOrigin.unit,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/widget/components/comments_input_widget_test.dart',
      origin: QALabTestOrigin.widget,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/widget/components/feed_header_actions_widget_test.dart',
      origin: QALabTestOrigin.widget,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/widget/components/market_top_actions_widget_test.dart',
      origin: QALabTestOrigin.widget,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/widget/components/notifications_menu_widget_test.dart',
      origin: QALabTestOrigin.widget,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/widget/components/widget_test.dart',
      origin: QALabTestOrigin.widget,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/widget/p0/full_screen_image_viewer_widget_test.dart',
      origin: QALabTestOrigin.widget,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/widget/p0/post_state_messages_widget_test.dart',
      origin: QALabTestOrigin.widget,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/widget/p0/reshare_attribution_widget_test.dart',
      origin: QALabTestOrigin.widget,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/widget/flows/accessibility_semantics_smoke_test.dart',
      origin: QALabTestOrigin.widget,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/widget/screens/chat_search_widget_test.dart',
      origin: QALabTestOrigin.widget,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'test/widget/screens/sign_in_test.dart',
      origin: QALabTestOrigin.widget,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'functions/tests/rules/firestore.rules.test.js',
      origin: QALabTestOrigin.backend,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'functions/tests/rules/storage.rules.test.js',
      origin: QALabTestOrigin.backend,
      runnableInApp: false,
    ),
    QALabCatalogEntry(
      path: 'functions/tests/unit/rateLimiter.test.js',
      origin: QALabTestOrigin.backend,
      runnableInApp: false,
    ),
  ];

  static List<String> inferTags(String path) {
    final lower = path.toLowerCase();
    if (lower.contains('turqapp_complete')) {
      return <String>[
        'splash',
        'login',
        'feed',
        'comments',
        'profile',
        'settings',
        'explore',
        'pasaj',
        'chat',
        'short',
        'notifications',
        'composer',
      ];
    }

    final tags = <String>{};

    void add(String value) {
      if (value.trim().isNotEmpty) {
        tags.add(value.trim());
      }
    }

    if (lower.contains('/auth/') || lower.contains('login')) {
      add('auth');
      add('login');
      add('splash');
    }
    if (lower.contains('/feed/') || lower.contains('feed_')) {
      add('feed');
    }
    if (lower.contains('/short') || lower.contains('/shorts/')) {
      add('short');
      add('scroll');
    }
    if (lower.contains('/chat/') || lower.contains('message')) {
      add('chat');
      add('message');
    }
    if (lower.contains('/comments/')) {
      add('comments');
    }
    if (lower.contains('/notifications/')) {
      add('notifications');
    }
    if (lower.contains('/story/')) {
      add('story');
    }
    if (lower.contains('/profile/')) {
      add('profile');
    }
    if (lower.contains('/explore/')) {
      add('explore');
    }
    if (lower.contains('/education/') ||
        lower.contains('/market/') ||
        lower.contains('practice') ||
        lower.contains('question_bank')) {
      add('pasaj');
      add('education');
    }
    if (lower.contains('/system/') || lower.contains('process_death')) {
      add('system');
    }
    if (lower.contains('permission')) {
      add('permissions');
      add('settings');
    }
    if (lower.contains('settings')) {
      add('settings');
    }
    if (lower.contains('upload')) {
      add('upload');
    }
    if (lower.contains('cache')) {
      add('cache');
    }
    if (lower.contains('hls')) {
      add('hls');
      add('video');
    }
    if (lower.contains('video') ||
        lower.contains('playback') ||
        lower.contains('autoplay') ||
        lower.contains('fullscreen')) {
      add('video');
    }
    if (lower.contains('autoplay')) {
      add('autoplay');
    }
    if (lower.contains('playback')) {
      add('playback');
    }
    if (lower.contains('audio') || lower.contains('mute')) {
      add('audio');
    }
    if (lower.contains('network')) {
      add('network');
    }
    if (lower.contains('resume') || lower.contains('restore')) {
      add('resume');
    }
    if (lower.contains('scroll')) {
      add('scroll');
    }
    if (lower.contains('sign_in')) {
      add('login');
    }
    if (lower.contains('route') || lower.contains('deeplink')) {
      add('route');
    }
    if (lower.contains('rules')) {
      add('backend_rules');
    }
    if (lower.contains('rateLimiter'.toLowerCase())) {
      add('backend');
    }
    if (tags.isEmpty) {
      add('general');
    }
    return tags.toList(growable: false);
  }

  static List<QALabCatalogEntry> entriesForSurface(String surface) {
    final normalized = surface.trim().toLowerCase();
    return entries
        .where((entry) => entry.tags.contains(normalized))
        .toList(growable: false);
  }

  static QALabSurfaceCoverageReport surfaceCoverage(String surface) {
    final normalized = surface.trim().toLowerCase();
    final requiredTags = List<String>.from(
      focusSurfaceRequirements[normalized] ?? <String>[normalized],
    );
    final relevantEntries = entriesForSurface(normalized);
    final coveredTags = requiredTags
        .where(
          (tag) => relevantEntries.any((entry) => entry.tags.contains(tag)),
        )
        .toList(growable: false);
    final missingTags = requiredTags
        .where((tag) => !coveredTags.contains(tag))
        .toList(growable: false);

    var integrationCount = 0;
    var runnableInAppCount = 0;
    var suiteCount = 0;
    var unitCount = 0;
    var widgetCount = 0;
    var backendCount = 0;

    for (final entry in relevantEntries) {
      switch (entry.origin) {
        case QALabTestOrigin.integration:
          integrationCount += 1;
          break;
        case QALabTestOrigin.suite:
          suiteCount += 1;
          break;
        case QALabTestOrigin.unit:
          unitCount += 1;
          break;
        case QALabTestOrigin.widget:
          widgetCount += 1;
          break;
        case QALabTestOrigin.backend:
          backendCount += 1;
          break;
      }
      if (entry.runnableInApp) {
        runnableInAppCount += 1;
      }
    }

    return QALabSurfaceCoverageReport(
      surface: normalized,
      requiredTags: requiredTags,
      coveredTags: coveredTags,
      missingTags: missingTags,
      integrationCount: integrationCount,
      runnableInAppCount: runnableInAppCount,
      suiteCount: suiteCount,
      unitCount: unitCount,
      widgetCount: widgetCount,
      backendCount: backendCount,
    );
  }

  static List<QALabSurfaceCoverageReport> focusCoverageReports() {
    return focusSurfaces.map(surfaceCoverage).toList(growable: false);
  }

  static Map<String, dynamic> focusCoverageJson() {
    final reports = focusCoverageReports();
    final completeCount = reports.where((report) => report.complete).length;
    final averageCoverage = reports.isEmpty
        ? 1.0
        : reports
                .map((report) => report.coverageRatio)
                .fold<double>(0, (sum, ratio) => sum + ratio) /
            reports.length;
    return <String, dynamic>{
      'completeCount': completeCount,
      'surfaceCount': reports.length,
      'averageCoverage': averageCoverage,
      'surfaces': reports.map((report) => report.toJson()).toList(
            growable: false,
          ),
    };
  }

  static Map<String, dynamic> summaryJson() {
    final byOrigin = <String, int>{};
    final byTag = <String, int>{};
    var runnableInAppCount = 0;
    for (final entry in entries) {
      byOrigin.update(entry.origin.name, (value) => value + 1,
          ifAbsent: () => 1);
      if (entry.runnableInApp) {
        runnableInAppCount += 1;
      }
      for (final tag in entry.tags) {
        byTag.update(tag, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    return <String, dynamic>{
      'totalCount': entries.length,
      'runnableInAppCount': runnableInAppCount,
      'byOrigin': byOrigin,
      'byTag': byTag,
      'focusCoverage': focusCoverageJson(),
    };
  }
}
