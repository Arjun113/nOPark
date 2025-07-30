import 'rideOffer.dart';
import 'location.dart';
import '../driver/driver_model.dart';
import 'car.dart';

class RideRequest {
  final Driver driver;
  Location currentLocation;
  List<RideOffer> rideOffers;
  final Car car;

  RideRequest({
    required this.driver,
    required this.currentLocation,
    required this.rideOffers,
    required this.car,
  });

  void addNewAcceptedOffer(RideOffer offer) {
    rideOffers.add(offer);
  }
}
