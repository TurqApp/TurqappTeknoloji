import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Utils/user_scoped_key.dart';

part 'draft_service_base_part.dart';
part 'draft_service_class_part.dart';
part 'draft_service_drafts_part.dart';
part 'draft_service_facade_part.dart';
part 'draft_service_fields_part.dart';
part 'draft_service_models_part.dart';
part 'draft_service_storage_part.dart';
