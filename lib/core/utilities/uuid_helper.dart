import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String generateUuidV7() {
  return _uuid.v7();
}
