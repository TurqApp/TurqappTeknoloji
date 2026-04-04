part of 'qa_lab_catalog.dart';

const List<String> _qaLabFocusSurfaces = <String>[
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

const Map<String, List<String>> _qaLabFocusSurfaceRequirements =
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

const List<QALabCatalogEntry> _qaLabCatalogEntries = <QALabCatalogEntry>[
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
    path: 'integration_test/comments/comment_surface_regression_e2e_test.dart',
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
    path: 'integration_test/shorts/short_offline_cache_fallback_test.dart',
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
    path: 'integration_test/system/permission_os_denied_state_smoke_test.dart',
    origin: QALabTestOrigin.integration,
    runnableInApp: true,
  ),
  QALabCatalogEntry(
    path: 'integration_test/system/permission_os_granted_state_smoke_test.dart',
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
    path: 'config/test_suites/feed_black_flash_only_e2e.txt',
    origin: QALabTestOrigin.suite,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'config/test_suites/feed_playback_gate_e2e.txt',
    origin: QALabTestOrigin.suite,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'config/test_suites/feed_seed_focus_e2e.txt',
    origin: QALabTestOrigin.suite,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'config/test_suites/short_first_two_only_e2e.txt',
    origin: QALabTestOrigin.suite,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'config/test_suites/short_five_only_e2e.txt',
    origin: QALabTestOrigin.suite,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'config/test_suites/short_ten_only_e2e.txt',
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
    path: 'test/unit/services/device_log_reporter_test.dart',
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
    path:
        'test/unit/modules/in_app_notifications/notification_post_types_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/modules/post_creator/composer_hashtag_utils_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/modules/profile/liked_posts_controller_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/services/playback_kpi_service_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/services/post_caption_limits_test.dart',
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
    path: 'test/unit/services/read_budget_contract_test.dart',
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
    path: 'test/unit/services/upload_validation_service_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/services/visibility_policy_service_test.dart',
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
    path: 'test/unit/utils/app_translations_placeholder_style_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/utils/runtime_invariant_guard_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/widget/integration/press_it_key_gesture_detector_test.dart',
    origin: QALabTestOrigin.widget,
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
    path: 'test/widget/p0/language_selector_widget_test.dart',
    origin: QALabTestOrigin.widget,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/widget/p0/post_state_messages_widget_test.dart',
    origin: QALabTestOrigin.widget,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/widget/p0/image_preview_widget_test.dart',
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
  QALabCatalogEntry(
    path: 'functions/tests/unit/notificationPushPolicy.test.js',
    origin: QALabTestOrigin.backend,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'integration_test/auth/auth_startup_session_restore_test.dart',
    origin: QALabTestOrigin.integration,
    runnableInApp: true,
  ),
  QALabCatalogEntry(
    path: 'integration_test/feed/feed_primary_bootstrap_contract_test.dart',
    origin: QALabTestOrigin.integration,
    runnableInApp: true,
  ),
  QALabCatalogEntry(
    path: 'config/test_suites/auth_session_feed_regression.txt',
    origin: QALabTestOrigin.suite,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'config/test_suites/rules_runtime_regression.txt',
    origin: QALabTestOrigin.suite,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/core/blocked_texts_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/core/services/feed_render_coordinator_build_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/core/services/prefetch_scheduler_policy_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/core/services/feed_playback_selection_policy_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/modules/agenda/agenda_feed_application_service_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/modules/chat_conversation_application_service_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path:
        'test/unit/modules/playback_runtime/playback_cache_runtime_service_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/modules/profile/ads_center_application_service_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/modules/post_creator/post_creator_flood_identity_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/modules/runtime_feature_services_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/modules/short/short_feed_application_service_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/modules/sign_in/sign_in_application_service_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/modules/splash/splash_bootstrap_roles_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/modules/splash/startup_route_hint_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/modules/story/story_row_application_service_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/modules/story/story_video_prefetch_wiring_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/repositories/feed_home_contract_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/services/account_session_vault_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/services/current_user_service_role_split_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/services/cache_invalidation_service_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/services/segment_cache_models_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/services/video_state_manager_on_demand_fetch_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'test/unit/utils/stored_account_reauth_policy_test.dart',
    origin: QALabTestOrigin.unit,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'functions/tests/unit/marketCounters.test.js',
    origin: QALabTestOrigin.backend,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'functions/tests/unit/hybridFeedContract.test.js',
    origin: QALabTestOrigin.backend,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'functions/tests/unit/moderationSecurityRegression.test.js',
    origin: QALabTestOrigin.backend,
    runnableInApp: false,
  ),
  QALabCatalogEntry(
    path: 'functions/tests/unit/reportsAuth.test.js',
    origin: QALabTestOrigin.backend,
    runnableInApp: false,
  ),
];
