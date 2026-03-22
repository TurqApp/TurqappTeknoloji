import 'package:mockito/mockito.dart';

abstract class AppRepository {
  Future<String> fetchUserName();
  Future<void> logout();
}

class MockRepository extends Mock implements AppRepository {}
