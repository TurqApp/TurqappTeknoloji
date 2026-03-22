import 'package:mockito/mockito.dart';

abstract class Storage {
  Future<void> save(String value);
  String? read();
  Future<void> clear();
}

class MockStorage extends Mock implements Storage {}
