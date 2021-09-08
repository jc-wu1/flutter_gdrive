import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis_auth/auth_io.dart';

class SecureStorage {
  final storage = const FlutterSecureStorage();

  Future saveCredentials(AccessToken token, String refreshToken) async {
    debugPrint(token.expiry.toIso8601String());
    await storage.write(key: "type", value: token.type);
    await storage.write(key: "data", value: token.data);
    await storage.write(key: "expiry", value: token.expiry.toString());
    await storage.write(key: "refreshToken", value: refreshToken);
  }

  Future<Map<String, dynamic>?> getCredentials() async {
    final result = await storage.readAll();
    if (result.isEmpty) return null;
    return result;
  }

  Future clear() {
    return storage.deleteAll();
  }
}
