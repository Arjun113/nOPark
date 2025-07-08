import 'package:nopark/features/trip/passenger/entities/passenger_model.dart';
import '../driver/driver_model.dart';

import 'user.dart';
import 'location.dart';

class RideOffer {
  final String rideOfferId;
  final Location originAddress;
  final Location destinationAddress;
  final Passenger passenger;
  final Driver driver;
  final double price;
  final double recommendedBid;
  final String status;
  final bool accepted;


  RideOffer ({
    required this.accepted,
    required this.originAddress,
    required this.destinationAddress,
    required this.passenger,
    required this.driver,
    required this.price,
    required this.recommendedBid,
    required this.rideOfferId,
    required this.status
  });
}