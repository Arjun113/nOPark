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
    required this.onRideCompleted,
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
    fetchCarDetails();
  }

  Future<void> fetchCarDetails() async {
    // Fetch car details and store them as needed
    try {
      final carDetailsResponse = await DioClient().client.get(
        '/accounts/vehicle?user_id=${widget.rideDataShare.getCurrentPassengerRideProposal()!.driverID}',
      );

      if (carDetailsResponse.data == null) {
        debugPrint("No car details found in response");
        return;
      }

      debugPrint(carDetailsResponse.data.toString());

      if (carDetailsResponse.statusCode != 200) {
        carDetails = Car(
          carLicensePlate: "DEMO12",
          carMake: "Demo",
          carModel: "Demo",
          carImage: "https://images.netdirector.co.uk/gforces-auto/image/upload/q_auto,c_fill,f_auto,fl_lossy/auto-client/ac0ffd18e7a826e2a1559978ff3a21fa/e_200.png",
          carColour: "White",
          carModelYear: "1984",
        );
        return;
      }

      setState(() {
        carDetails = Car(
          carLicensePlate:
              carDetailsResponse.data['license_plate'] as String? ?? '',
          carMake: carDetailsResponse.data['make'] as String? ?? '',
          carModel: carDetailsResponse.data['model'] as String? ?? '',
          carImage: "https://images.netdirector.co.uk/gforces-auto/image/upload/q_auto,c_fill,f_auto,fl_lossy/auto-client/ac0ffd18e7a826e2a1559978ff3a21fa/e_200.png",
          carColour: carDetailsResponse.data['colour'] as String? ?? '',
          carModelYear: carDetailsResponse.data['model_year']?.toString() ?? '',
        );
      });

      debugPrint(carDetails.toString());
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching car details:$e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if required data is available
    if (carDetails == null) {
      return const Center(child: CircularProgressIndicator());
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Image.network(carDetails!.carImage, height: 120),
              const SizedBox(height: 10),
              Text(
                (carDetails!.carMake) + (carDetails!.carModel),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                carDetails!.carColour,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 13),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
