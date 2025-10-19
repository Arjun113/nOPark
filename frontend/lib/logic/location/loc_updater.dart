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
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );
      print('Location sent: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('Error sending location: $e');
    }
  }

  void stopLocationUpdates() {
    _positionStream.cancel();
    _sendTimer.cancel();
  }
}