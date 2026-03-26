part of 'warm_launch_pool.dart';

abstract class _WarmLaunchPoolBase extends GetxService {
  _WarmLaunchPoolBase(this._delegate);

  final IndexPoolStore _delegate;
}
