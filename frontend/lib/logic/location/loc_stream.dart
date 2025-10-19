import 'dart:async';

import 'package:geolocator/geolocator.dart';

final minimumDistance = 50;

final LocationSettings settings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: minimumDistance,
);

Stream<Position> locationStream = Geolocator.getPositionStream(
  locationSettings: settings,
);
