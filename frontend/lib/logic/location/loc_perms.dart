import 'package:permission_handler/permission_handler.dart';

Future<void> requestLocationPermission() async {
  if (await Permission.location.isDenied) {
    await Permission.location.request();
  }
}