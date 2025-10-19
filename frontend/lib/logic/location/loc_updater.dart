import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:nopark/logic/location/loc_stream.dart';

import '../network/dio_client.dart';

class LocationService {
  late Timer _sendTimer;
  late Position _latestPosition;
  late StreamSubscription<Position> _positionStream;

  void startLocationUpdates() {
    // Listen to your existing location stream
    _positionStream = locationStream.listen((Position position) {
      // Just store the latest position
      _latestPosition = position;
    });

    // Send location every 10 seconds
    _sendTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _sendLocationToServer(_latestPosition);
    });
  }

  Future<void> _sendLocationToServer(Position position) async {
    try {
      await DioClient().client.put(
        '/accounts/location',
        data: {'lat': position.latitude, 'lon': position.longitude},
      );
    } catch (e) {
      // We would ideally handle the error here
    }
  }

  void stopLocationUpdates() {
    _positionStream.cancel();
    _sendTimer.cancel();
  }
}
