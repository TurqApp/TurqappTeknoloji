import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

const String kNotificationPostTypeUser = 'User';
const String kNotificationPostTypeComment = 'Comment';
const String kNotificationPostTypeChat = 'Chat';
const String kNotificationPostTypePosts = 'Posts';
const String kNotificationPostTypeJobApplication = 'JobApplication';
const String kNotificationPostTypeTutoringApplication = 'TutoringApplication';

const String kNotificationPostTypeUserLower = 'user';
const String kNotificationPostTypeCommentLower = 'comment';
const String kNotificationPostTypeChatLower = 'chat';
const String kNotificationPostTypePostsLower = 'posts';
const String kNotificationPostTypeJobApplicationLower = 'jobapplication';
const String kNotificationPostTypeTutoringApplicationLower =
    'tutoringapplication';

const Set<String> kNotificationPostTypesLower = {
  kNotificationPostTypePostsLower,
  'like',
  kNotificationPostTypeCommentLower,
  'reshared_posts',
  'shared_as_posts',
  'reshare',
  'post',
};

const Set<String> kListingNotificationTypesLower = {
  'job_application',
  'tutoring_application',
  'tutoring_status',
  'market_offer',
  'market_offer_status',
};

const Set<String> kListingNotificationPostTypesLower = {
  kNotificationPostTypeJobApplicationLower,
  kNotificationPostTypeTutoringApplicationLower,
  'market',
  'market_chat',
};

const Set<String> kJobNotificationTypesLower = {
  'job_application',
  'market_offer',
};

const Set<String> kTutoringNotificationTypesLower = {
  'tutoring_application',
  'tutoring_status',
};

String notificationPostTypeFromEventType(String type) {
  switch (type) {
    case 'follow':
    case kNotificationPostTypeUser:
      return kNotificationPostTypeUser;
    case 'comment':
    case kNotificationPostTypeComment:
      return kNotificationPostTypeComment;
    case 'message':
    case kNotificationPostTypeChat:
      return kNotificationPostTypeChat;
    case 'job_application':
      return kNotificationPostTypeJobApplication;
    case 'tutoring_application':
    case 'tutoring_status':
      return kNotificationPostTypeTutoringApplication;
    case 'like':
    case 'reshared_posts':
    case 'shared_as_posts':
    case 'reshare':
    case kNotificationPostTypePosts:
    default:
      return kNotificationPostTypePosts;
  }
}

String normalizeNotificationType(String type, String postType) {
  final normalizedType = normalizeSearchText(type);
  if (normalizedType.isNotEmpty) return normalizedType;
  return normalizeSearchText(postType);
}

bool isNotificationPostType(String normalizedType) {
  return kNotificationPostTypesLower.contains(normalizedType);
}

bool isListingNotificationType(String normalizedType) {
  return kListingNotificationTypesLower.contains(normalizedType);
}

bool isListingNotificationPostType(String normalizedPostType) {
  return kListingNotificationPostTypesLower.contains(normalizedPostType);
}

bool isJobNotificationType(String normalizedType) {
  return kJobNotificationTypesLower.contains(normalizedType);
}

bool isTutoringNotificationType(String normalizedType) {
  return kTutoringNotificationTypesLower.contains(normalizedType);
}

String notificationDescriptionKeyForType(String type) {
  switch (type) {
    case 'like':
      return 'notification.desc.like';
    case 'comment':
      return 'notification.desc.comment';
    case 'reshared_posts':
      return 'notification.desc.reshare';
    case 'shared_as_posts':
    case 'reshare':
      return 'notification.desc.share';
    case 'follow':
    case kNotificationPostTypeUser:
      return 'notification.desc.follow';
    case 'message':
    case kNotificationPostTypeChat:
      return 'notification.desc.message';
    case 'job_application':
      return 'notification.desc.job_application';
    case 'tutoring_application':
      return 'notification.desc.tutoring_application';
    case 'tutoring_status':
      return 'notification.desc.tutoring_status';
    default:
      return '';
  }
}

String normalizeNotificationCreateType(String type) {
  final normalizedType = normalizeSearchText(type);
  switch (normalizedType) {
    case 'follow':
    case 'user':
      return 'follow';
    case 'message':
    case 'chat':
      return 'message';
    case 'comment':
      return 'comment';
    case 'like':
      return 'like';
    case 'reshared_posts':
      return 'reshared_posts';
    case 'shared_as_posts':
    case 'reshare':
      return 'shared_as_posts';
    case 'posts':
    case 'post':
    default:
      return kNotificationPostTypePosts;
  }
}
