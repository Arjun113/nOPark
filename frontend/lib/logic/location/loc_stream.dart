import 'dart:async';

import 'package:geolocator/geolocator.dart';

final minimumDistance = 200;
final timeLimit = 5000; // It is in miliseconds, so 5s

final LocationSettings settings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: minimumDistance,
  timeLimit: Duration(milliseconds: timeLimit),
);

Stream<Position> locationStream = Geolocator.getPositionStream(
  locationSettings: settings,);
