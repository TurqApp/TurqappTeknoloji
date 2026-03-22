import 'package:mockito/annotations.dart';

import 'api/mock_api.dart';
import 'repositories/mock_repository.dart';
import 'storage/mock_storage.dart';

@GenerateNiceMocks([
  MockSpec<ApiService>(),
  MockSpec<Storage>(),
  MockSpec<AppRepository>(),
])
void main() {}
