import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/render_list_patch.dart';
import 'package:turqappv2/Core/Utils/location_text_utils.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'feed_render_coordinator_build_part.dart';
part 'feed_render_coordinator_patch_part.dart';

class FeedRenderCoordinator extends GetxService {
  static FeedRenderCoordinator? maybeFind() {
    final isRegistered = Get.isRegistered<FeedRenderCoordinator>();
    if (!isRegistered) return null;
    return Get.find<FeedRenderCoordinator>();
  }

  static FeedRenderCoordinator ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(FeedRenderCoordinator(), permanent: true);
  }
}
