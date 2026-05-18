import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppTaskController {
  const AppTaskController();

  static const MethodChannel _channel = MethodChannel(
    'turqapp.app_task/method',
  );

  Future<bool> moveTaskToBack() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('moveTaskToBack') ?? false;
    } catch (error) {
      debugPrint('[AppTask] action=moveTaskToBack_failed error=$error');
      return false;
    }
  }
}
