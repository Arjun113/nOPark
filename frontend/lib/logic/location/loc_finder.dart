import 'package:geolocator/geolocator.dart';

Future<Position?> getLocationTemp() async {
  bool locationEnabled;
  LocationPermission perms;
  LocationAccuracyStatus accuracy;

  // If permission not there, ask for it
  locationEnabled = await Geolocator.isLocationServiceEnabled();
  if (!locationEnabled) {
    return Future.error('Location services have been disabled on this device.');
  }

  perms = await Geolocator.checkPermission();
  if (perms == LocationPermission.denied) {
    perms = await Geolocator.requestPermission();
  } else {
    accuracy = await Geolocator.getLocationAccuracy();
    if (accuracy == LocationAccuracyStatus.reduced) {
      Geolocator.requestTemporaryFullAccuracy(
        purposeKey:
            'We require your precise location to be able to navigate you',
      );
      accuracy = await Geolocator.getLocationAccuracy();
      if (accuracy == LocationAccuracyStatus.reduced) {
        return Future.error('Location services cannot be provided.');
      }
    }
  }

  if (perms == LocationPermission.deniedForever) {
    return Future.error(
      'Location services have been denied forever on this device.',
    );
  }

  return await Geolocator.getCurrentPosition();
}
