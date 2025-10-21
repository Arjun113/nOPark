import 'package:flutter/material.dart';
import 'package:nopark/features/feeds/datamodels/data_controller.dart';
import 'package:nopark/features/trip/entities/car.dart';
import 'package:nopark/logic/network/dio_client.dart';

class RideCard extends StatefulWidget {
  final DataController rideDataShare;
  final VoidCallback? onRideCompleted;

  const RideCard({
    super.key,
    required this.rideDataShare,
    required this.onRideCompleted
  });

  @override
  State<StatefulWidget> createState() {
    return RideCardState();
  }
}

class RideCardState extends State<RideCard> {
  Car? carDetails;
  @override
  void initState() {
    super.initState();
    if (mounted) {
      widget.onRideCompleted?.call();
    }
    // Get car details
  }

  Future<void> fetchCarDetails () async {
    // Fetch car details and store them as needed
    try {
      final car_details = await DioClient().client.get(
        '/accounts/vehicle?user_id=${widget.rideDataShare.getCurrentPassengerRideProposal()!.driverID}'
      );

      if (car_details.statusCode != 200) {
        carDetails = Car(carLicensePlate: "DEMO12", carMake: "Demo", carModel: "Demo", carImage: "", carColour: "White", carModelYear: "1984");
        return;
      }

      carDetails = Car(
          carLicensePlate: car_details.data['license_plate'],
          carMake: car_details.data['make'],
          carModel: car_details.data['model'],
          carImage: "",
          carColour: car_details.data['colour'],
          carModelYear: car_details.data['model_year']);
    }
    catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching car details")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if required data is available
    if (carDetails == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 470,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "You are on your way!",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Image.network(carDetails!.carImage, height: 120),
                const SizedBox(height: 10),
                Text(
                  (carDetails!.carMake ?? "") + (carDetails!.carModel),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  carDetails!.carColour,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        carDetails!.carLicensePlate,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      Text(
                        "VIC",
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}