import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/tutoring_repository.dart';
import 'package:turqappv2/Core/Repositories/tutoring_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'my_tutorings_controller_class_part.dart';
part 'my_tutorings_controller_facade_part.dart';
part 'my_tutorings_controller_fields_part.dart';
part 'my_tutorings_controller_runtime_part.dart';
part 'my_tutorings_controller_sync_part.dart';
