import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  static Future<void> setLoginToken(String token) async {
    FlutterSecureStorage storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );

    storage.write(key: 'authToken', value: token);
  }
}
