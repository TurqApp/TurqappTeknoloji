import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/typesense_market_service.dart';
import 'package:turqappv2/Models/market_item_model.dart';

part 'market_repository_action_part.dart';
part 'market_repository_cache_part.dart';
part 'market_repository_class_part.dart';
part 'market_repository_facade_part.dart';
part 'market_repository_fields_part.dart';
part 'market_repository_models_part.dart';
part 'market_repository_query_part.dart';
