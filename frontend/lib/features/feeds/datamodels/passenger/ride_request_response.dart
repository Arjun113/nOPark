import '../../../trip/entities/location.dart';

class RideRequestResponse {
  final String pickupLocation;
  final Location pickupCoordinates;
  final String dropoffLocation;
  final Location dropoffCoordinates;
  final double initialCompensation;
  final int passengerID;
  final String createdAt;

  const RideRequestResponse({
    required this.dropoffLocation,
    required this.initialCompensation,
    required this.dropoffCoordinates,
    required this.pickupCoordinates,
    required this.pickupLocation,
    required this.passengerID,
    required this.createdAt
});

  factory RideRequestResponse.fromJson(Map<String, dynamic> json) {
    return RideRequestResponse(
      pickupLocation: (json['pickup_location'] ?? "") as String,
      initialCompensation: (json['compensation'] ?? 0) as double,
      pickupCoordinates: Location(
        lat: (json['pickup_latitude'] as num?)?.toDouble() ?? 0.0,
        long: (json['pickup_longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      dropoffCoordinates: Location(
        lat: (json['dropoff_latitude'] as num?)?.toDouble() ?? 0.0,
        long: (json['dropoff_longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      dropoffLocation: (json['dropoff_location'] ?? "") as String,
      passengerID: (json['passenger_id'] as num?)?.toInt() ?? 0,
      createdAt: (json['created_at'] ?? "") as String
    );
  }
}