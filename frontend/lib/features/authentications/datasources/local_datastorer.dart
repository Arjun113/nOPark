import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nopark/features/trip/entities/user.dart';

class CredentialStorage {
  static Future<bool> doesLoginExist() async {
    FlutterSecureStorage storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    final bool doesTokenExist = await storage.containsKey(key: 'authToken');

    if (doesTokenExist == false) {
      return false;
    }
    return true;
  }

  static Future<String?> fetchLoginToken() async {
    final bool doesLogin = await CredentialStorage.doesLoginExist();
    if (doesLogin == false) {
      return null;
    }

    FlutterSecureStorage storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    final String? authToken = await storage.read(key: 'authToken');
    return authToken;
  }

  static Future<void> setUser(User user) async {
    FlutterSecureStorage storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    final String userJson = jsonEncode(user.toJson());
    await storage.write(key: 'user', value: userJson);
  }

  static Future<User?> getUser() async {
    FlutterSecureStorage storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final userJson = await storage.read(key: 'user');
    if (userJson == null) return null;

    final Map<String, dynamic> userMap = jsonDecode(userJson);
    return User.fromJson(userMap);
  }

  static Future<void> setLoginToken(String token) async {
    FlutterSecureStorage storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    storage.write(key: 'authToken', value: token);
  }

  static Future<void> deleteLoginToken() async {
    FlutterSecureStorage storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    storage.delete(key: 'authToken');
  }
}
