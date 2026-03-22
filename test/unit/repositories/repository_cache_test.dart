import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../mocks/mock_api.dart';
import '../../mocks/mock_storage.dart';

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
  late MockApiService api;
  late MockStorage storage;
  late Repository repo;

  setUp(() {
    api = MockApiService();
    storage = MockStorage();
    repo = Repository(api, storage);
  });

  test('Fetch from API and cache', () async {
    when(api.getData()).thenAnswer((_) async => 'DATA');
    when(storage.save(any)).thenAnswer((_) async {});

    final result = await repo.getData();

    verify(storage.save('DATA')).called(1);
    expect(result, 'DATA');
  });

  test('Fetch from cache when offline', () async {
    when(api.getData()).thenThrow(Exception());
    when(storage.read()).thenReturn('CACHED');

    final result = await repo.getData();

    expect(result, 'CACHED');
  });
}
