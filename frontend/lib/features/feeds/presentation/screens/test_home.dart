import 'package:flutter/material.dart';
import 'package:nopark/features/feeds/presentation/widgets/full_screen_map.dart';
import 'package:nopark/features/feeds/presentation/widgets/where_next_location_picker.dart';
import 'package:nopark/features/profiles/presentation/widgets/address_scroller.dart';
import 'package:nopark/features/trip/entities/user.dart';

class HomePage extends StatelessWidget {
  final User user;
  final List<Map<String, dynamic>> addresses;

  const HomePage({
    super.key,
    required this.user,
    required this.addresses
  });

  List<AddressCardData> convertListToAddressCard() {
    return addresses.map((elem) => AddressCardData(name: elem['name'], line1: elem['line1'], line2: elem['line2'], editing: false)).toList();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background map
          FullScreenMap(),

          // Greeting + profile picture
          Positioned(
            top: 60,
            left: 20,
            child: Text(
              "Hello ${user.firstName}",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: CircleAvatar(
              radius: 24,
              backgroundImage: AssetImage(user.imageUrl),
            ),
          ),

          // Bottom card with buttons
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Existing Where to next button
                      WhereToNextWidget(
                          userName: user.firstName,
                          profileURL: user.imageUrl,
                          addresses: convertListToAddressCard(),
                          onAddressSelected: ((String x) => "x")
                      ),

                      const SizedBox(height: 12),

                      // View past rides button
                      GestureDetector(
                        onTap: null,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.directions_car),
                              SizedBox(width: 8),
                              Text(
                                "View Past Rides",
                                style: TextStyle(fontSize: 16),
                              ),
                              Spacer(),
                              Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
