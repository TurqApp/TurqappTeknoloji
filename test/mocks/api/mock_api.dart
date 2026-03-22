import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

abstract class ApiService {
  Future<http.Response> login(String username, String password);
  Future<String> getData();
}

class MockApiService extends Mock implements ApiService {}
