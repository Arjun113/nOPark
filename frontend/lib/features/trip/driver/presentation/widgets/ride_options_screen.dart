import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

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

  const RideOption({
    required this.name,
    required this.rating,
    required this.address,
    required this.addressCoords,
    required this.detourKm,
    required this.detourMin,
    required this.price,
    required this.proposalID
  });
}

Future<List<RideOption>> fetchObjects (Location coords, String destination) async {
  List<RideOption> possible_rides = [];
  try {
    final response = await DioClient().client.get(
      '/rides/requests',
      data: {
        'dropoff_lat': coords.lat,
        'dropoff_lon': coords.long
      }
    );

    if (response.statusCode != 201) {
      return [];
    }

    final mainData = response.data['requests'] as List<Map<String, dynamic>>;

    // This has passenger ID; we need passenger name and rating also
    for (int i = 0; i < mainData.length; i = i + 1) {
      final passenger_response = await DioClient().client.get(
        '/accounts/${mainData[i]['passenger_id']}'
      );

      if (response.statusCode != 201) {
        return possible_rides;
      }

      final newRide = RideOption(name: passenger_response.data['first_name'] + passenger_response.data['last_name'],
          rating: passenger_response.data['rating'],
          address: destination, addressCoords: coords,
          detourKm: response.data['detour_km'],
          detourMin: response.data['detour_min'],
          price: response.data['compensation'],
          proposalID: response.data['id']
      );

      possible_rides.add(newRide);
    }
  }
  catch (e) {
    // Add context if needed
  }

  return possible_rides;
}

class RideOptionsScreen extends StatefulWidget {
  final String destination;
  final Location destinationCoords;
  final String? destinationCode;
  final ValueChanged<List<int>>? onSelectionChanged;
  final void Function (List<int> selections) onConfirm;

  const RideOptionsScreen({
    super.key,
    required this.destination,
    required this.destinationCoords,
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
            future: fetchObjects(widget.destinationCoords, widget.destination),
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
                              color: isSelected
                                  ? Colors.blue[100]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
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
                        for (int i = 0; i < selectedIndices.length; i = i + 1){
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