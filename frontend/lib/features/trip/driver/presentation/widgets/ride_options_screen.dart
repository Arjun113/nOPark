import 'package:flutter/material.dart';

// Data model for Ride Options
class RideOption {
  final String name;
  final double rating;
  final String address;
  final double detourKm;
  final int detourMin;
  final double price;

  RideOption({
    required this.name,
    required this.rating,
    required this.address,
    required this.detourKm,
    required this.detourMin,
    required this.price,
  });
}

// Mock backend data (replace later with API call)
Future<List<RideOption>> fetchRideOptions() async {
  await Future.delayed(const Duration(seconds: 1)); // simulate network delay
  return [
    RideOption(
      name: "Lachlan MacPhee",
      rating: 4.8,
      address: "1341 Dandenong Road, Chadstone, VIC",
      detourKm: 2.7,
      detourMin: 7,
      price: 18.04,
    ),
    RideOption(
      name: "Taiyeb M. Radiowala",
      rating: 4.7,
      address: "37 Alliance Walk, Clayton, VIC",
      detourKm: 1.7,
      detourMin: 7,
      price: 8.04,
    ),
    RideOption(
      name: "Arjun Sanghi",
      rating: 4.0,
      address: "37 Alliance Walk, Clayton, VIC",
      detourKm: 1.7,
      detourMin: 7,
      price: 4.04,
    ),
  ];
}

class RideOptionsScreen extends StatefulWidget {
  final String destination;
  final String? destinationCode;
  final ValueChanged<List<int>>? onSelectionChanged;

  const RideOptionsScreen({
    super.key,
    required this.destination,
    this.destinationCode,
    this.onSelectionChanged,
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
            future: fetchRideOptions(),
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
                      maxHeight: MediaQuery
                          .of(context)
                          .size
                          .height * 0.6,
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
                                  "${ride.detourKm}km detour (+${ride
                                      .detourMin}min)",
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
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}