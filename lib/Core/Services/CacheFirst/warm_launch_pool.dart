import 'package:turqappv2/Core/Services/IndexPool/index_pool_store.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'warm_launch_pool_facade_part.dart';
part 'warm_launch_pool_members_part.dart';

/// Transitional facade over [IndexPoolStore].
///
/// This layer makes the intended role explicit:
/// fast warm launches for renderable post cards, not the long-term scoped
/// snapshot contract used by primary surfaces.
class WarmLaunchPool extends _WarmLaunchPoolBase {
  WarmLaunchPool({
    IndexPoolStore? delegate,
  }) : super(delegate ?? IndexPoolStore());
}
