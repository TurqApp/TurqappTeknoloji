part of 'short_content_controller.dart';

final PostInteractionService _shortInteractionService =
    PostInteractionService.ensure();
final PostRepository _shortPostRepository = PostRepository.ensure();
final UserSummaryResolver _shortUserSummaryResolver =
    UserSummaryResolver.ensure();

String get _shortCurrentUserId => CurrentUserService.instance.effectiveUserId;
