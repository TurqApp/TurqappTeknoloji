part of 'cikmis_sorular_repository_parts.dart';

class CikmisSorularRepository extends _CikmisSorularRepositoryBase {
  CikmisSorularRepository({
    FirebaseStorage? storage,
  }) : super(storage: storage ?? FirebaseStorage.instance);
}
