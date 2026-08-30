import 'dart:convert';

import 'package:crypto/crypto.dart';

class PasswordHasher {
  const PasswordHasher._();

  static String hash(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }
}
