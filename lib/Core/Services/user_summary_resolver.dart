import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/typesense_user_card_cache_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';

part 'user_summary_resolver_data_part.dart';
part 'user_summary_resolver_facade_part.dart';

class UserSummaryResolver extends GetxService {
  static UserSummaryResolver? maybeFind() => _maybeFindUserSummaryResolver();

  static UserSummaryResolver ensure() => _ensureUserSummaryResolver();

  UserRepository get _users => UserRepository.ensure();
  TypesenseUserCardCacheService get _typesenseCards =>
      TypesenseUserCardCacheService.ensure();
}
