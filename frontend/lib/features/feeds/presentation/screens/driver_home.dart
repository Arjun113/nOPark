import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:latlong2/latlong.dart';
import 'package:nopark/features/authentications/datasources/local_datastorer.dart';
import 'package:nopark/features/feeds/datamodels/data_controller.dart';
import 'package:nopark/features/feeds/presentation/widgets/full_screen_map.dart';
import 'package:nopark/features/profiles/presentation/widgets/address_scroller.dart';
import 'package:nopark/features/profiles/presentation/widgets/profile_modal.dart';
import 'package:nopark/features/trip/driver/presentation/widgets/passenger_pickup_seq.dart';
import 'package:nopark/features/trip/driver/presentation/widgets/ride_in_progress.dart';
import 'package:nopark/features/trip/driver/presentation/widgets/ride_options_screen.dart';
import 'package:nopark/features/trip/entities/user.dart';
import 'package:nopark/features/trip/passenger/presentation/widgets/trip_cost_adjust_widget.dart';
import 'package:nopark/features/trip/passenger/presentation/widgets/trip_over_card_rating.dart';
import 'package:nopark/features/trip/unified/trip_scroller.dart';
import 'package:nopark/logic/utilities/firebase_notif_waiter.dart';

import '../../../../logic/map/polyline_decoder.dart';
import '../../../../logic/network/dio_client.dart';
import '../../../trip/entities/location.dart';
import '../widgets/base_where_next.dart';
import '../widgets/where_next_overlay.dart';
import 'overlay_flow.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

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

  // User and address data from CredentialStorage
  User? user;
  List<Map<String, dynamic>> addresses = [];
  bool isLoading = true;

  get collapse => null;

  DataController rideDataStore = DataController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final loadedUser = await CredentialStorage.getUser();
    setState(() {
      user = loadedUser;
      addresses =
          loadedUser?.addresses
              .map((addr) => {'name': addr, 'line1': addr, 'line2': ''})
              .toList() ??
          [];
      isLoading = false;
    });
  }

  List<AddressCardData> convertListToAddressCard() {
    return addresses
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
                      user: user!,
                      addresses: addresses,
                      onLocationSelected: (lat, lng, name, code) async {
                        final List<MapMarker> destinationMarker = [
                          MapMarker(position: LatLng(lat, lng)),
                        ];
                        // Get the route from server
                        List<LatLng>? route;
                        try {
                          final polylineGetter = await DioClient().client.post(
                            '/maps/route',
                            data: {
                              'start_lat':
                                  mapKey
                                      .currentState
                                      ?.currentLocation
                                      ?.latitude,
                              'start_lng':
                                  mapKey
                                      .currentState
                                      ?.currentLocation
                                      ?.longitude,
                              'end_lat': lat,
                              'end_lng': lng,
                            },
                          );

                          if (polylineGetter.statusCode != 200) {
                            route = [];
                          } else {
                            // Get the route
                            route = decodePolyline(
                              polylineGetter.data['polyline'],
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error getting route details"),
                            ),
                          );
                        }

                        _updateMap(destinationMarker, route!);
                        rideDataStore.setCurrentDestination(
                          Location(lat: lat, long: lng),
                        );
                        rideDataStore.setCurrentDestinationString(name);
                        rideDataStore.setDestinationCode(code);
                        controller.next();
                      },
                      onBack: Navigator.of(context).pop,
                      initialPosition: position,
                      initialSize: size,
                    ),

                    RideOptionsScreen(
                      rideDataStore: rideDataStore,
                      destinationCode: null,
                      onConfirm: (proposalIndices) async {
                        // TODO: Send the selections to the backend
                        try {
                          // Send the preferences to the backend
                          print(proposalIndices);
                          final response = await DioClient().client.post(
                            '/rides/',
                            data: {
                              'request_ids': proposalIndices,
                              'destination_lat':
                                  rideDataStore.getCurrentDestination()!.lat,
                              'destination_lon':
                                  rideDataStore.getCurrentDestination()!.long,
                            },
                          );

                          if (response.statusCode != 201) {
                            return;
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }

                        // Wait for the Ride ID to be allocated
                        RemoteMessage message = await waitForRideUpdates(
                          'ride_finalized',
                        );
                        rideDataStore.setFinalRideId(
                          int.parse(message.data['ride_id']),
                        );
                        rideDataStore.setDriverAcceptedProposals(proposalIndices);

                        controller.next();
                      },
                    ),

                    PickupSequenceWidget(
                      rideData: rideDataStore,
                      onLocationReached: ((index) async {
                        debugPrint("reached top line of onlocationreached");
                        if (index <
                            rideDataStore
                                .getDriverAcceptedProposals()!
                                .length) {
                          // Tell API to ping passenger
                          try {
                            final locReachedResponse = await DioClient().client
                                .post(
                                  '/rides/pickup',
                                  data: {
                                    'ride_id': rideDataStore.getFinalRideId(),
                                    'current_lat':
                                        mapKey
                                            .currentState
                                            ?.currentLocation
                                            ?.latitude,
                                    'current_lon':
                                        mapKey
                                            .currentState
                                            ?.currentLocation
                                            ?.longitude,
                                  },
                                );

                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Error communicating with the server: $e",
                                ),
                              ),
                            );
                          }
                        }

                        debugPrint(index.toString());
                        debugPrint(rideDataStore.getDriverAcceptedProposals()!.toString());

                        // If this is the last pickup, move to next screen
                        if (index ==
                            rideDataStore.getDriverAcceptedProposals()!.length -
                                1) {
                          controller.next();
                        }
                      }),
                    ),

                    // Card showing ride in progress and waiting for completion
                    DriverRideCard(
                        title: "Ride In Progress",
                        onRideCompleted: () async {
                          // Send ride completion to backend

                          try {
                            final complete_ride_response = await DioClient().client.post(
                              '/rides/complete',
                              data: {
                                'ride_id': rideDataStore.getFinalRideId()
                              }
                            );
                          }
                          catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error closing ride: $e")));
                          }

                          // Move to ride rating completion widget
                          controller.next();
                        }
                    ),

                    RideCompletionWidget(
                      riders: rideDataStore.getCurrentRiderInfo('driver'),
                      moveToZero: (() {
                        rideDataStore.clearForNextRide();
                        controller.jumpTo(0);
                      }),
                    ),
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
                    PastRidesOverlay(onBack: () => Navigator.of(context).pop()),
                  ],
            ),
      ),
    );
  }

  void _updateMap(List<MapMarker> mapMarkers, List<LatLng> routePoints) {
    mapMarkers.map((marker) {
      rideDataStore.addDestinationMarker(marker);
    });
    rideDataStore.setRoutePoints(routePoints);
    mapKey.currentState?.fitBoundsToShowAllMarkers();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Failed to load user data')),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background map
          FullScreenMap(key: mapKey, rideDataShare: rideDataStore,userType: 'driver',),

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
              top: 58,
              left: 30,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  "Hello, ${user?.firstName ?? 'Guest'}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
            Positioned(
              top: 58,
              right: 30,
              child: GestureDetector(
                onTap: () {
                  if (user != null) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      builder:
                          (context) => ProfileBottomSheet(
                            user: user!,
                            userRole: 'Driver',
                            emailController: TextEditingController(
                              text: user!.email,
                            ),
                            addresses: addresses,
                              onLogOut: (() async {
                                try {
                                  final response = await DioClient().client.post(
                                    '/accounts/logout',
                                  );

                                  if (response.statusCode == 200) {
                                    CredentialStorage.deleteLoginToken();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Successfully Logged Out"),
                                      ),
                                    );
                                    Navigator.of(context).pushNamedAndRemoveUntil(
                                      '/login',
                                          (Route<dynamic> route) => false,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Unable to log out."),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Unable to contact server."),
                                    ),
                                  );
                                }
                              })
                          ),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(
                      user?.imageUrl ?? User.defaultImageUrl,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
