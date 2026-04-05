import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Ads/admob_kare.dart';

part 'admob_banner_warmup_service_runtime_part.dart';
part 'admob_banner_warmup_service_facade_part.dart';

/// Global AdMob banner warmup rules.
///
/// We treat banner inventory as an app-wide warm pool instead of creating
/// independent speculative warmups on every page.
class AdmobBannerWarmupService extends GetxService {
  static const int steadyStateTarget = 10;
  static const int lowWaterMark = 5;
  static const int topUpBatchSize = 5;
  static const int splashFirstLaunchTarget = steadyStateTarget;
  static const int splashDefaultTarget = steadyStateTarget;
  static const int feedEntryTarget = steadyStateTarget;
  static const int pasajEntryTarget = steadyStateTarget;
  static const Duration _entryWarmupMinInterval = Duration(seconds: 20);
  static const Duration _secondaryTopUpDelay = Duration(milliseconds: 2500);

  Future<void>? _initFuture;
  bool _sdkReady = false;
  final Map<String, DateTime> _lastWarmupAtBySurface = <String, DateTime>{};
}
