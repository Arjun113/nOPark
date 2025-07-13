import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../logic/error/exceptions.dart';

abstract class SharedPreferences {
  Future<bool> doesLoginExist();
  Future<void> setLogin(String email, String password);
}

class SharedPreferencesImplement {
  final keystore = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  final String emailKeyname = 'email';
  final String passwordKeyname = 'password';
  final String lastAccessDateKeyName = 'lastAccessDate';
  final int lastAccessTimeout = 14;

  Future<bool> doesLoginExist() async {
    try {
      final String? lastAccessDt = await keystore.read(key: lastAccessDateKeyName);

     // If the last access date exists (which it won't on first load) or it is old, ask for reauth

      if (lastAccessDt == null || (DateTime.parse(lastAccessDt).add(Duration(days: 14)).isBefore(DateTime.now()))) {
        return false;
      }
      else {
        return true;
      }
    }
    catch (err) {
      throw CacheException;
    }
  }

  Future <void> setLogin (String email, String password) async {
    await keystore.write(key: emailKeyname, value: email);
    await keystore.write(key: passwordKeyname, value: password);
    await keystore.write(key: lastAccessDateKeyName, value: DateTime.now().toString());
  }

}