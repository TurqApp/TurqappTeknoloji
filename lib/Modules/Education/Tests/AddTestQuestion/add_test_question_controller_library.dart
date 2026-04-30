import 'dart:io';

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/legacy_tests_feature_gate.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';

part 'add_test_question_controller_actions_part.dart';
part 'add_test_question_controller_base_part.dart';
part 'add_test_question_controller_class_part.dart';
part 'add_test_question_controller_data_part.dart';
part 'add_test_question_controller_facade_part.dart';
part 'add_test_question_controller_fields_part.dart';

const _addQuestionMiddleSchoolType = 'Ortaokul';
