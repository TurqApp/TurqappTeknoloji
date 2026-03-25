import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/integration_test_mode.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/typesense_post_service.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../Models/posts_model.dart';
import '../../Models/post_sharers_model.dart';
import '../../Services/post_count_manager.dart';
import '../../Services/post_interaction_service.dart';

part 'post_repository_interaction_part.dart';
part 'post_repository_facade_part.dart';
part 'post_repository_models_part.dart';
part 'post_repository_query_part.dart';
part 'post_repository_sharing_part.dart';
part 'post_repository_support_part.dart';

class PostRepository extends GetxService {
  PostRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    PostInteractionService? interactionService,
    PostCountManager? countManager,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _interactionService =
            interactionService ?? PostInteractionService.ensure(),
        _countManager = countManager ?? PostCountManager.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PostInteractionService _interactionService;
  final PostCountManager _countManager;
  final TypesensePostService _typesensePostService =
      TypesensePostService.instance;
  final Map<String, PostRepositoryState> _states =
      <String, PostRepositoryState>{};
  final Map<String, List<PostSharersModel>> _postSharersMemory =
      <String, List<PostSharersModel>>{};
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  static PostRepository? maybeFind() => _maybeFindPostRepository();

  static PostRepository ensure() => _ensurePostRepository();
}
