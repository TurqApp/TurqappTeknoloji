import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../mocks/api/mock_api.dart';
import '../../mocks/storage/mock_storage.dart';

class FakeApiService implements ApiService {
  FakeApiService({
    required this.loginHandler,
    required this.dataHandler,
  });

  final Future<http.Response> Function(String username, String password)
      loginHandler;
  final Future<String> Function() dataHandler;

  @override
  Future<String> getData() => dataHandler();

  @override
  Future<http.Response> login(String username, String password) {
    return loginHandler(username, password);
  }
}

class FakeStorage implements Storage {
  String? cachedValue;
  int saveCallCount = 0;

  @override
  Future<void> clear() async {
    cachedValue = null;
  }

  @override
  String? read() => cachedValue;

  @override
  Future<void> save(String value) async {
    saveCallCount += 1;
    cachedValue = value;
  }
}

class Repository {
  Repository(this.api, this.storage);

  final ApiService api;
  final Storage storage;

  Future<String> getData() async {
    try {
      final result = await api.getData();
      await storage.save(result);
      return result;
    } catch (_) {
      final cached = storage.read();
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }
}

void main() {
  test('Fetch from API and cache', () async {
    final api = FakeApiService(
      loginHandler: (_, __) async => http.Response('', 200),
      dataHandler: () async => 'DATA',
    );
    final storage = FakeStorage();
    final repo = Repository(api, storage);

    final result = await repo.getData();

    expect(storage.saveCallCount, 1);
    expect(storage.cachedValue, 'DATA');
    expect(result, 'DATA');
  });

  test('Fetch from cache when offline', () async {
    final api = FakeApiService(
      loginHandler: (_, __) async => http.Response('', 200),
      dataHandler: () async => throw Exception('offline'),
    );
    final storage = FakeStorage()..cachedValue = 'CACHED';
    final repo = Repository(api, storage);

    final result = await repo.getData();

    expect(result, 'CACHED');
  });
}
