import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' hide Location;
import 'package:latlong2/latlong.dart';
import 'package:nopark/features/feeds/datamodels/data_controller.dart';
import 'package:nopark/features/feeds/datamodels/driver/user_data.dart';
import 'package:nopark/features/feeds/datamodels/passenger/ride_proposal.dart';
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

  DataController rideDataStore = DataController();

  // User and address data from CredentialStorage
  User? user;
  List<Map<String, dynamic>> addresses = [];
  bool isLoading = true;

  get collapse => null;

  @override
  void initState(){
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
    print("User data loaded");
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
                        rideDataStore.setCurrentDestination(Location(lat: lat, long: lng));

                        // Get the recommended bid amount
                        try {
                          final response = await DioClient().client.get(
                              '/rides/compensation',
                              data: {
                                "start_longitude": mapKey.currentState?.currentLocation?.longitude,
                                "start_latitude": mapKey.currentState?.currentLocation?.latitude,
                                "end_longitude": lng,
                                "end_latitude": lat
                              }
                          );

                          if (response.statusCode == 200) {
                            // All ok
                            rideDataStore.setCurrentRideInitialCompensation(response.data['estimated_comp'] as double);
                          }
                          else {
                            return;
                          }
                        }
                        catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error contacting server. ${e}")));
                        }

                        rideDataStore.setCurrentDestinationString((await placemarkFromCoordinates(lat, lng))[0].name!);
                        rideDataStore.setCurrentStartingString((await placemarkFromCoordinates(mapKey.currentState!.currentLocation!.latitude, mapKey.currentState!.currentLocation!.longitude))[0].name!);

                        controller.next();
                      },
                      onBack: Navigator.of(context).pop,
                      initialPosition: position,
                      initialSize: size,
                    ),

                    PricingOverlay(
                      onBack: controller.back,
                      fromAddressName: rideDataStore.getCurrentStartingString(),
                      fromCampusCode: null,
                      toAddressName: rideDataStore.getCurrentDestinationString(),
                      toCampusCode: null,
                      recommendedBidAUD: rideDataStore.getCurrentRideInitialCompensation(),
                      initialSize: size,
                      initialPosition: position,
                      onSubmit: ((newBid) async {
                        // Engage popup
                        DriverSearchOverlay.show(context);

                        try{
                          final response = await DioClient().client.post(
                            '/rides/requests',
                            data: {
                              "pickup_location": rideDataStore.getCurrentStartingString(),
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
                              "dropoff_location": rideDataStore.getCurrentDestinationString(),
                              "dropoff_latitude": rideDataStore.getCurrentDestination()!.lat,
                              "dropoff_longitude": rideDataStore.getCurrentDestination()!.long,
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
                              rideDataStore.setRideReqResp(RideRequestResponse.fromJson(
                                response.data,
                              ));
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
                        RemoteMessage driver_prospectus = await waitForJob("ride_created");

                        // TODO: Pull the ride proposal and chuck it in the alert dialog
                        try {
                          final proposal_data = await DioClient().client.get(
                            '/rides/proposals',
                            data: {
                              "proposal_id": driver_prospectus.data['proposal_id']
                            }
                          );

                          if (proposal_data.statusCode != 201) {
                            return;
                          }

                          rideDataStore.setCurrentPassengerRideProposal(RideProposal.fromJson(proposal_data.data));

                          // Now get driver details
                          final driver_data = await DioClient().client.get(
                            '/accounts/${rideDataStore.getCurrentPassengerRideProposal()!.driverID}'
                          );

                          if (driver_data.statusCode != 201) {
                            return;
                          }

                          rideDataStore.setCurrentUserResponse(UserResponse.fromJson(driver_data.data));
                        }
                        catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error talking to server.")));
                        }

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
                                    Text("Driver name: ${rideDataStore.getCurrentUserResponse()!.firstName}"),
                                    Text("Driver rating: ${rideDataStore.getCurrentUserResponse()!.rating} (${rideDataStore.getCurrentUserResponse()!.ratingCount})"),
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
                                  driver_prospectus.data['proposal_id'],
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
                            rideDataStore.clearForNextRide();
                            controller.jumpTo(0);
                          }
                        controller.next();
                      }),
                    ),

                    DriverInfoCard(
                      driverName: rideDataStore.getCurrentUserResponse(),
                      profileImageUrl: "",
                      lookForCompletion: (() async {
                        // TODO: Wait for pickup to say yes

                        final rider_picked_up = await waitForJob('proximity');

                        controller.next();
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
                      onRideCompleted: (() async {
                        // TODO: Wait for ride to finish

                        final rider_ride_done = await waitForJob('ride_completed');

                        controller.next();
                      }),
                    ),

                    RideCompletionWidget(
                      riders: rideDataStore.getCurrentRiderInfo('passenger'),
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
                    PastRidesOverlay(
                      onBack: () => Navigator.of(context).pop(),
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
