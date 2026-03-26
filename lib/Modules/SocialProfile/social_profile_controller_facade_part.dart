part of 'social_profile_controller.dart';

SocialProfileController ensureSocialProfileController({
  required String userID,
  String? tag,
  bool permanent = false,
}) =>
    _ensureSocialProfileController(
      userID: userID,
      tag: tag,
      permanent: permanent,
    );

SocialProfileController? maybeFindSocialProfileController({String? tag}) =>
    _maybeFindSocialProfileController(tag: tag);
