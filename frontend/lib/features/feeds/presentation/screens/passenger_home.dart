import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:latlong2/latlong.dart';
import 'package:nopark/features/feeds/datamodels/passenger/ride_request_response.dart';
import 'package:nopark/features/feeds/presentation/widgets/full_screen_map.dart';
import 'package:nopark/features/profiles/presentation/widgets/address_scroller.dart';
import 'package:nopark/features/profiles/presentation/widgets/profile_modal.dart';
import 'package:nopark/features/trip/entities/user.dart';
import 'package:nopark/features/trip/passenger/presentation/widgets/driver_contact_card.dart';
import 'package:nopark/features/trip/passenger/presentation/widgets/ride_card.dart';
import 'package:nopark/features/trip/passenger/presentation/widgets/trip_cost_adjust_widget.dart';
import 'package:nopark/features/trip/passenger/presentation/widgets/trip_over_card_rating.dart';
import 'package:nopark/features/trip/passenger/presentation/widgets/trip_search_animation.dart';
import 'package:nopark/features/trip/unified/trip_scroller.dart';
import 'package:nopark/home_test.dart';
import 'package:nopark/logic/network/dio_client.dart';
import 'package:nopark/logic/routing/basic_two_router.dart';
import 'package:nopark/logic/utilities/firebase_notif_waiter.dart';

import '../../../authentications/datasources/local_datastorer.dart';
import '../../../trip/entities/location.dart';
import '../widgets/base_where_next.dart';
import '../widgets/where_next_overlay.dart';
import 'overlay_flow.dart';

class PassengerHomePage extends StatefulWidget {
  const PassengerHomePage({super.key});

  @override
  State<PassengerHomePage> createState() => _PassengerHomePageState();
}

class _PassengerHomePageState extends State<PassengerHomePage> {
  bool isExpanded = false;
  OverlayEntry? whereNextOverlay;
  final GlobalKey<WhereNextState> whereNextKey = GlobalKey<WhereNextState>();
  final GlobalKey whereNextButtonKey = GlobalKey(); // Key for the button
  final GlobalKey<PricingOverlayState> pricingOverlayKey =
      GlobalKey<PricingOverlayState>();
  final GlobalKey<FullScreenMapState> mapKey = GlobalKey<FullScreenMapState>();

  // Variables for the flow system
  Location? destination;
  RideRequestResponse? rideReqResp;
  int? prospectiveRideId;
  double? initialCompensation;
  String? destinationString;

  // User and address data from CredentialStorage
  User? user;
  List<Map<String, dynamic>> addresses = [];
  bool isLoading = true;

  get collapse => null;

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
                    PricingOverlay(
                      onBack: controller.back,
                      fromAddressName: "Current Location",
                      fromCampusCode: null,
                      toAddressName: "Woodside",
                      toCampusCode: null,
                      recommendedBidAUD: 15,
                      initialSize: size,
                      initialPosition: position,
                      onSubmit: ((newBid) async {
                        // Engage popup
                        DriverSearchOverlay.show(context);

                        try {
                          final originCoord = await placemarkFromCoordinates(
                            mapKey.currentState!.currentLocation!.latitude,
                            mapKey.currentState!.currentLocation!.longitude,
                          );
                          final destCoord = await placemarkFromCoordinates(
                            mapKey
                                .currentState!
                                .destinationMarker[0]
                                .position
                                .latitude,
                            mapKey
                                .currentState!
                                .destinationMarker[0]
                                .position
                                .longitude,
                          );

                          final response = await DioClient().client.post(
                            '/rides/requests',
                            data: {
                              "pickup_location": originCoord[0].name,
                              "pickup_latitude":
                                  mapKey
                                      .currentState!
                                      .currentLocation!
                                      .latitude,
                              "pickup_longitude":
                                  mapKey
                                      .currentState!
                                      .currentLocation!
                                      .longitude,
                              "dropoff_location": destCoord[0].name,
                              "dropoff_latitude":
                                  mapKey
                                      .currentState!
                                      .destinationMarker[0]
                                      .position
                                      .latitude,
                              "dropoff_longitude":
                                  mapKey
                                      .currentState!
                                      .destinationMarker[0]
                                      .position
                                      .longitude,
                              "compensation": newBid,
                            },
                          );

                          if (response.statusCode == 201) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Ride created successfully!"),
                                ),
                              );
                              rideReqResp = RideRequestResponse.fromJson(
                                response.data,
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Error encountered in creating the ride. Please try again!",
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error contacting the server."),
                              ),
                            );
                          }
                        }

                        // Wait for FCM notification about prospective ride
                        RemoteMessage driverProspectus = await waitForJob(
                          "passengerRideProposal",
                        );
                        RemoteMessage driver_prospectus = await waitForJob("ride_created");

                        // TODO: Pull the ride proposal and chuck it in the alert dialog


                        // Store the prospective ride ID
                        bool acception = await showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text("Please confirm the ride."),
                                content: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Driver name: "),
                                    Text("Driver rating: "),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        (() => Navigator.of(context).pop(true)),
                                    child: Text("Accept Ride"),
                                  ),
                                  TextButton(
                                    onPressed:
                                        (() =>
                                            Navigator.of(context).pop(false)),
                                    child: Text("Reject Ride"),
                                  ),
                                ],
                              ),
                        );

                        // Send server yes or no
                        try {
                          final response = await DioClient().client.post(
                            '/rides/confirm',
                            data: {
                              'proposal_id':
                                  driverProspectus.data['proposal_id'],
                              'confirm':
                                  acception == true ? 'accept' : 'reject',
                            },
                          );

                          if (response.statusCode == 201) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Ride acceptance or denial sent",
                                  ),
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Ride acceptance or denial could not be successfully communicated",
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Error communicating with the server",
                                ),
                              ),
                            );
                          }
                        }

                          // Go back to home if rejected.

                          if (acception == false) {
                            controller.jumpTo(0);
                            rideReqResp = null;
                            prospectiveRideId = null;
                            destination = null;
                          }

                        controller.next();
                      }),
                    ),
                    DriverInfoCard(
                      driverName: "Woo Jun Jian",
                      profileImageUrl:
                          "https://www.google.com/url?sa=i&url=https%3A%2F%2Fwww.vecteezy.com%2Ffree-vector%2Fprofile-icon&psig=AOvVaw3jdm_m4NfZ0qKHYFgzApd5&ust=1756697553023000&source=images&cd=vfe&opi=89978449&ved=0CBYQjRxqFwoTCJCZv7-OtI8DFQAAAAAdAAAAABAE",
                      lookForCompletion: (() {
                        // TODO: Ride completion endpoint
                        Future.delayed(Duration(seconds: 10), () {
                          controller.next();
                        });
                      }),
                    ),
                    RideCard(
                      title: "Trip in Progress",
                      carName: "Mercedes C200",
                      carColor: "White",
                      plateNumber: "ABC123",
                      plateState: "VIC",
                      carImageUrl:
                          "https://www.mercedes-benz.com.au/content/dam/hq/passengercars/cars/c-class/c-class-saloon-w206-pi/modeloverview/06-2022/images/mercedes-benz-c-class-w206-modeloverview-696x392-06-2022.png",
                      onRideCompleted: (() {
                        // TODO: Wait for ride to finish

                        // For now, use mock
                        Future.delayed(Duration(seconds: 10), () {
                          controller.next();
                        });
                      }),
                    ),
                    RideCompletionWidget(
                      riderName: "Jun Woo Jian",
                      price: "14.85",
                      moveToZero: (() {
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
                "Hello ${user?.firstName ?? 'Guest'}",
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
                  if (user != null) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      builder:
                          (context) => ProfileBottomSheet(
                            user: user!,
                            userRole: 'Passenger',
                            emailController: TextEditingController(
                              text: user!.email,
                            ),
                            addresses: addresses,
                            onLogOut: (() async {
                              try {
                                // TODO: Lachlan and Taiyeb: clear cred store
                                final response = await DioClient().client.post(
                                    '/accounts/logout',
                                    data: {}
                                );

                                if (response.statusCode == 201) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Successfully Logged Out"))
                                  );
                                  Navigator.pushReplacementNamed(context, '/login');
                                }
                                else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Unable to log out."))
                                  );
                                }
                              }
                              catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Unable to contact server."))
                                );
                              }
                            }),
                          ),
                    );
                  }
                },
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(
                    user?.imageUrl ?? User.defaultImageUrl,
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
