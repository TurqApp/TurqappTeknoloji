import 'dart:async';
import 'dart:io';
import 'package:contact_add/contact.dart';
import 'package:contact_add/contact_add.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/conversation_repository.dart';
import 'package:turqappv2/Core/Repositories/notify_lookup_repository.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/BottomSheets/show_action_sheet.dart';
import 'package:turqappv2/Core/Helpers/safe_external_link_guard.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Models/message_model.dart';
import 'package:turqappv2/Modules/Chat/chat_controller.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../Models/posts_model.dart';

part 'message_content_controller_base_part.dart';
part 'message_content_controller_class_part.dart';
part 'message_content_controller_fields_part.dart';
part 'message_content_controller_data_part.dart';
part 'message_content_controller_actions_part.dart';
part 'message_content_controller_facade_part.dart';
