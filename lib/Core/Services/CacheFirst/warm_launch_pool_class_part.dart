part of 'warm_launch_pool.dart';

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
