import 'dart:io';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Helpers/GlobalLoader/global_loader_controller.dart';
import 'package:turqappv2/Core/Helpers/UnreadMessagesController/unread_messages_controller.dart';
import 'package:turqappv2/Core/Services/Ads/admob_banner_warmup_service.dart';
import 'package:turqappv2/Core/Services/Ads/admob_unit_config_service.dart';
import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_policy_engine.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/user_profile_cache_service.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Education/education_controller.dart';
import 'package:turqappv2/Modules/Explore/explore_controller.dart';
import 'package:turqappv2/Modules/JobFinder/job_finder_controller.dart';
import 'package:turqappv2/Modules/NavBar/nav_bar_controller.dart';
import 'package:turqappv2/Modules/Profile/MyProfile/profile_controller.dart';
import 'package:turqappv2/Modules/Profile/SavedPosts/saved_posts_controller.dart';
import 'package:turqappv2/Modules/RecommendedUserList/recommended_user_list_controller.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Runtime/feature_runtime_services.dart';
import 'package:turqappv2/Services/offline_mode_service.dart';
import 'package:turqappv2/Services/story_interaction_optimizer.dart';
import 'package:turqappv2/Core/Services/deep_link_service.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';

class DependencyRegistrar {
  DependencyRegistrar({
    void Function()? registerDependencies,
  }) : _registerDependencies =
            registerDependencies ?? _defaultRegisterDependencies;

  final void Function() _registerDependencies;

  void register() => _registerDependencies();

  static void _defaultRegisterDependencies() {
    Get.lazyPut(() => NetworkAwarenessService());
    Get.lazyPut(() => OfflineModeService.instance);

    GlobalLoaderController.ensure();
    ensureAdmobBannerWarmupService();
    ensureAdmobUnitConfigService(permanent: true);
    ensureStoryInteractionOptimizer();
    Get.lazyPut(() => UnreadMessagesController());
    if (maybeFindNavBarController() == null) {
      Get.put(NavBarController(), permanent: true);
    }
    Get.lazyPut(() => ProfileController());
    if (maybeFindAgendaController() == null) {
      Get.put(AgendaController(), permanent: true);
    }
    Get.lazyPut(() => RecommendedUserListController(), fenix: true);
    Get.lazyPut(() => ExploreController());
    Get.lazyPut(() => ShortController());
    Get.lazyPut(() => EducationController());
    Get.lazyPut(() => SavedPostsController());
    Get.lazyPut(() => JobFinderController());
    Get.lazyPut(() => StoryRowController(), fenix: true);
    const UploadQueueRuntimeService().ensureReady(permanent: true);
    if (!Platform.isIOS) {
      ensureDeepLinkService();
    }
    IndexPoolStore.ensure(permanent: true);
    ensureUserProfileCacheService();
    StorageBudgetManager.ensure();
    ensurePlaybackPolicyEngine();
    ensurePlaybackKpiService();
  }
}
