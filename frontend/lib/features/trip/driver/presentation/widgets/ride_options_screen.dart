import 'package:flutter/material.dart';
import 'package:nopark/features/feeds/datamodels/data_controller.dart';

import '../../../../../logic/network/dio_client.dart';
import '../../../entities/location.dart';

// Data model for Ride Options
class RideOption {
  final String name;
  final double rating;
  final String address;
  final Location addressCoords;
  final double detourKm;
  final int detourMin;
  final double price;
  final int proposalID;
  final String polyline;
  final int passengerID;

  const RideOption({
    required this.name,
    required this.rating,
    required this.address,
    required this.addressCoords,
    required this.detourKm,
    required this.detourMin,
    required this.price,
    required this.proposalID,
    required this.polyline,
    required this.passengerID,
  });
}

Future<List<RideOption>> fetchObjects(DataController rideDataStore) async {
  List<RideOption> possibleRides = [];
  try {
    final response = await DioClient().client.get(
      '/rides/requests',
      data: {
        'dropoff_lat': rideDataStore.getCurrentDestination()!.lat,
        'dropoff_lon': rideDataStore.getCurrentDestination()!.long,
      },
    );

    if (response.statusCode != 201) {
      return [];
    }

    final mainData = response.data['requests'] as List<Map<String, dynamic>>;

    // This has passenger ID; we need passenger name and rating also
    for (int i = 0; i < mainData.length; i = i + 1) {
      final passengerResponse = await DioClient().client.get(
        '/accounts/${mainData[i]['passenger_id']}',
      );

      if (response.statusCode != 201) {
        return possibleRides;
      }

      final newRide = RideOption(
        name:
            passengerResponse.data['first_name'] +
            passengerResponse.data['last_name'],
        rating: passengerResponse.data['rating'],
        address: response.data['dropoff_location'],
        addressCoords: Location(
          lat: response.data['dropoff_latitude'],
          long: response.data['dropoff_longitude'],
        ),
        detourKm: response.data['detour_km'],
        detourMin: response.data['detour_min'],
        price: response.data['compensation'],
        proposalID: response.data['id'],
        polyline: response.data['polyline'],
        passengerID: mainData[i]['passenger_id'] as int,
      );

      possibleRides.add(newRide);
    }
  } catch (e) {
    // Add context if needed
  }
  rideDataStore.setDriverReceivedProposalDetails(possibleRides);
  return possibleRides;
}

class RideOptionsScreen extends StatefulWidget {
  final String? destinationCode;
  final DataController? rideDataStore;
  final ValueChanged<List<int>>? onSelectionChanged;
  final void Function(List<int> selections) onConfirm;

  const RideOptionsScreen({
    super.key,
    required this.rideDataStore,
    this.destinationCode,
    this.onSelectionChanged,
    required this.onConfirm,
  });

  @override
  State<RideOptionsScreen> createState() => _RideOptionsScreenState();
}

class _RideOptionsScreenState extends State<RideOptionsScreen> {
  List<int> selectedIndices = [];

  void _handleSelection(int index) {
    setState(() {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index);
      } else {
        selectedIndices.add(index);
      }
    });
    widget.onSelectionChanged?.call(selectedIndices);
  }

  @override
  Widget build(BuildContext context) {
    // Check if required data is available
    if (widget.rideDataStore == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: FutureBuilder<List<RideOption>>(
            future: fetchObjects(widget.rideDataStore!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text("Error loading ride options"),
                  ),
                );
              }

              final rides = snapshot.data ?? [];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rides list
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: rides.length,
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        final isSelected = selectedIndices.contains(index);

                        return GestureDetector(
                          onTap: () => _handleSelection(index),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? Colors.blue[100]
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  isSelected
                                      ? Border.all(color: Colors.blue, width: 2)
                                      : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name + Rating
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      ride.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          ride.rating.toString(),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Address
                                Text(
                                  ride.address,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Detour
                                Text(
                                  "${ride.detourKm}km detour (+${ride.detourMin}min)",
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Price
                                Text(
                                  "AUD${ride.price.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Confirm button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: ElevatedButton(
                      onPressed: () {
                        List<int> proposalIds = [];
                        for (int i = 0; i < selectedIndices.length; i = i + 1) {
                          proposalIds.add(rides[i].proposalID);
                        }
                        widget.onConfirm(proposalIds);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[500],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirm Selection${selectedIndices.isEmpty ? '' : ' (${selectedIndices.length})'}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
