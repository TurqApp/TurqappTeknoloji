import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/render_list_patch.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'short_render_coordinator_class_part.dart';
part 'short_render_coordinator_patch_part.dart';
part 'short_render_coordinator_facade_part.dart';

class ShortRenderUpdate {
  const ShortRenderUpdate({
    required this.patch,
    required this.remappedIndex,
  });

  final RenderListPatch<PostsModel> patch;
  final int remappedIndex;
}
