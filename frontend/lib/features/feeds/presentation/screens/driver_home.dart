import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nopark/features/feeds/presentation/widgets/full_screen_map.dart';
import 'package:nopark/features/profiles/presentation/widgets/address_scroller.dart';
import 'package:nopark/features/profiles/presentation/widgets/profile_modal.dart';
import 'package:nopark/features/trip/driver/presentation/widgets/passenger_pickup_seq.dart';
import 'package:nopark/features/trip/driver/presentation/widgets/ride_options_screen.dart';
import 'package:nopark/features/trip/entities/user.dart';
import 'package:nopark/features/trip/passenger/presentation/widgets/driver_contact_card.dart';
import 'package:nopark/features/trip/passenger/presentation/widgets/ride_card.dart';
import 'package:nopark/features/trip/passenger/presentation/widgets/trip_cost_adjust_widget.dart';
import 'package:nopark/features/trip/passenger/presentation/widgets/trip_over_card_rating.dart';
import 'package:nopark/features/trip/passenger/presentation/widgets/trip_search_animation.dart';
import 'package:nopark/features/trip/unified/trip_scroller.dart';
import 'package:nopark/home_test.dart';
import 'package:nopark/logic/routing/basic_two_router.dart';

import '../widgets/base_where_next.dart';
import '../widgets/where_next_overlay.dart';
import 'overlay_flow.dart';

class DriverHomePage extends StatefulWidget {
  final User user;
  final List<Map<String, dynamic>> addresses;

  const DriverHomePage({super.key, required this.user, required this.addresses});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  bool isExpanded = false;
  OverlayEntry? whereNextOverlay;
  final GlobalKey<WhereNextState> whereNextKey = GlobalKey<WhereNextState>();
  final GlobalKey whereNextButtonKey = GlobalKey(); // Key for the button
  final GlobalKey<PricingOverlayState> pricingOverlayKey =
  GlobalKey<PricingOverlayState>();
  final GlobalKey<FullScreenMapState> mapKey = GlobalKey<FullScreenMapState>();

  get collapse => null;

  List<AddressCardData> convertListToAddressCard() {
    return widget.addresses
        .map(
          (elem) => AddressCardData(
        name: elem['name'],
        line1: elem['line1'],
        line2: elem['line2'],
        editing: false,
      ),
    )
        .toList();
  }

  void toggleExpansion() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  // Method to get the position and size of the WhereNext button
  (Offset, Size)? _getWhereNextPosition() {
    final renderBox =
    whereNextButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    return (position, size);
  }

  void _onWhereNextTap() {
    final positionData = _getWhereNextPosition();
    if (positionData == null) return;

    final (position, size) = positionData;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder:
            (_, __, ___) => OverlayFlow(
          onClose: () => Navigator.of(context).pop(),
          stepsBuilder:
              (controller) => [
            WhereNextOverlay(
              user: widget.user,
              addresses: widget.addresses,
              onLocationSelected: (lat, lng) async {
                final List<MapMarker> destinationMarker = [
                  MapMarker(position: LatLng(lat, lng)),
                ];
                final List<LatLng>? route =
                await RoutingService.getRoute(
                  mapKey.currentState?.currentLocation,
                  LatLng(lat, lng),
                );
                _updateMap(destinationMarker, route!);
                controller.next();
              },
              onBack: Navigator.of(context).pop,
              initialPosition: position,
              initialSize: size,
            ),
            RideOptionsScreen(
                destination: "Caulfield",
                destinationCode: "CA",
                onConfirm: (selectedIndices) async {
                  // TODO: Send the selections to the backend
                  // For now, mock. Remember to update the map later

                  controller.next();
                },
            ),
            PickupSequenceWidget(
                pickups: [
                  PickupInfo(name: "Lachlan MacPhee", rating: 4.8, address: "1341 Dandenong Road", detourKm: 5, detourMin: 20, price: 14.8, destinationCode: "CA", destination: "Caulfield")]
            )
          ],
        ),
      ),
    );
  }

  void _onPastRidesTap() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withAlpha(30),
        pageBuilder:
            (_, __, ___) => OverlayFlow(
          onClose: () => Navigator.of(context).pop(),
          stepsBuilder:
              (controller) => [
            PastRidesOverlay(
              onBack: () => Navigator.of(context).pop(),
              trips: [demoTrip],
            ),
          ],
        ),
      ),
    );
  }

  void _updateMap(List<MapMarker> mapMarkers, List<LatLng> routePoints) {
    mapMarkers.map((marker) {
      mapKey.currentState?.addDestinationMarker(marker);
    });
    mapKey.currentState?.setRoutePoints(routePoints);
    mapKey.currentState?.fitBoundsToShowAllMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background map
          FullScreenMap(key: mapKey),

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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        key: whereNextButtonKey, // Add the key here
                        onTap: _onWhereNextTap,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.location_on_outlined),
                              SizedBox(width: 8),
                              Text(
                                "Where to next?",
                                style: TextStyle(fontSize: 20),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      GestureDetector(
                        onTap: _onPastRidesTap,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 12,
                          ),
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
                      ),
                    ],
                  ),
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
                  fontFamily: 'Roboto',
                ),
              ),
            ),
            Positioned(
              top: 55,
              right: 30,
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    builder:
                        (context) => ProfileBottomSheet(
                      user: widget.user,
                      userRole: 'Passenger',
                      phoneController: TextEditingController(
                        text: widget.user.phoneNumber,
                      ),
                      emailController: TextEditingController(
                        text: widget.user.monashEmail,
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(widget.user.imageUrl),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
