import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:turqappv2/Core/Services/ContentPolicy/content_policy.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/eviction_scoring_engine.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/storage_budget_manager.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Models/posts_model.dart';

import 'cache_metrics.dart';
import 'models.dart';

part 'cache_manager_eviction_part.dart';
part 'cache_manager_base_part.dart';
part 'cache_manager_facade_part.dart';
part 'cache_manager_fields_part.dart';
part 'cache_manager_runtime_part.dart';
part 'cache_manager_storage_part.dart';
part 'cache_manager_write_part.dart';
