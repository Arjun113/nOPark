import 'package:flutter/material.dart';
import 'package:nopark/features/feeds/presentation/widgets/full_screen_map.dart';
import 'package:nopark/features/profiles/presentation/widgets/address_scroller.dart';
import 'package:nopark/features/trip/entities/user.dart';
import 'package:nopark/features/feeds/presentation/widgets/where_next_location_picker.dart';

import '../widgets/base_where_next.dart';

class HomePage extends StatefulWidget {
  final User user;
  final List<Map<String, dynamic>> addresses;

  const HomePage({
    super.key,
    required this.user,
    required this.addresses,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isExpanded = false;
  OverlayEntry? whereNextOverlay;
  final GlobalKey<WhereNextState> whereNextKey = GlobalKey<WhereNextState>();

  get collapse => null;

  List<AddressCardData> convertListToAddressCard() {
    return widget.addresses
        .map((elem) => AddressCardData(
      name: elem['name'],
      line1: elem['line1'],
      line2: elem['line2'],
      editing: false,
    ))
        .toList();
  }

  void toggleExpansion() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background map
          FullScreenMap(),

          // Detect taps outside when expanded
          if (isExpanded)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: collapse,
              child: Container(color: Colors.transparent),
            ),

          // Bottom card with View Past Rides
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
                  child: Column (
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WhereNext(user: widget.user, addresses: [], state: true),
                    GestureDetector(
                      onTap: null,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
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
                              style: TextStyle(fontSize: 20),
                            ),
                            Spacer(),
                            Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    )
                    ],
                  )
                ),
              ),
            ),
          ),


          // Greeting + profile picture (hidden when expanded to avoid overlap)
          if (!isExpanded) ...[
            Positioned(
              top: 60,
              left: 30,
              child: Text(
                "Hello ${widget.user.firstName}",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto'),
              ),
            ),
            Positioned(
              top: 55,
              right: 30,
              child: CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(widget.user.imageUrl),
              ),
            ),
          ]
        ],
      ),
    );
  }
}
