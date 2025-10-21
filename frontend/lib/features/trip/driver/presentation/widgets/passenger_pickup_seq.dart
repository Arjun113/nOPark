import 'package:flutter/material.dart';
import 'package:nopark/features/feeds/datamodels/data_controller.dart';
import 'package:nopark/features/trip/driver/presentation/widgets/ride_options_screen.dart';
import 'package:nopark/logic/network/dio_client.dart';

import '../../../entities/location.dart';

class PickupInfo {
  final String name;
  final int rating;
  final String address;
  final double detourKm;
  final int detourMin;
  final double price;
  final String destinationCode;
  final String destination;

  PickupInfo({
    required this.name,
    required this.rating,
    required this.address,
    required this.detourKm,
    required this.detourMin,
    required this.price,
    required this.destinationCode,
    required this.destination,
  });
}

class PickupSequenceWidget extends StatefulWidget {
  final DataController? rideData;
  final Stream<int>? locationStream;
  final Function(int)? onLocationReached;

  const PickupSequenceWidget({
    super.key,
    required this.rideData,
    this.locationStream,
    this.onLocationReached,
  });

  @override
  State<PickupSequenceWidget> createState() => _PickupSequenceWidgetState();
}

class _PickupSequenceWidgetState extends State<PickupSequenceWidget>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  List<RideOption>? pickups;
  List<String>? pickupAddresses;
  List<Location>? pickupAddressCoords;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Start the async initialization
    _initializePickups();
  }

  Future<void> _initializePickups() async {
    // Wait for required data to be available
    while (widget.rideData?.getFinalRideId() == null ||
        widget.rideData?.getDriverReceivedProposalDetails() == null) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    try {
      final allottedRideId = widget.rideData!.getFinalRideId();
      final receivedRequests =
          widget.rideData!.getDriverReceivedProposalDetails();

      // Pull ride data from backend to get proposal IDs
      final rideSummaryRequest = await DioClient().client.get(
        '/rides/summary?ride_id=$allottedRideId',
        data: {},
      );

      if (rideSummaryRequest.statusCode != 200) {
        if (mounted) {
          setState(() {
            pickups = [];
            pickupAddressCoords = [];
            pickupAddresses = [];
            _isLoading = false;
            _errorMessage = "Failed to fetch ride summary";
          });
        }
        return;
      }

      // All ok
      final listOfRides = rideSummaryRequest.data['proposals'] as List<dynamic>;
      List<RideOption> tempPickups = [];
      List<String> tempPickupAddresses = [];
      List<Location> tempPickupAddressesCoords = [];

      // Loop through list to counter check proposal IDs
      for (var ride in listOfRides) {
        final rideStatus = ride['status'];
        if (rideStatus == "accepted") {
          for (var rideRequest in receivedRequests!) {
            if (widget.rideData!.getDriverAcceptedProposals()!.contains(rideRequest.proposalID)) {
              tempPickups.add(rideRequest);
              tempPickupAddresses.add(ride['request']['pickup_location']);
              tempPickupAddressesCoords.add(Location(lat: ride['request']['pickup_latitude'], long: ride['request']['pickup_longitude']));
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          pickups = tempPickups;
          pickupAddressCoords = tempPickupAddressesCoords;
          pickupAddresses = tempPickupAddresses;
          _isLoading = false;
        });
        debugPrint(pickups.toString());
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error fetching ride details: $e";
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error fetching ride details.")));
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _moveToNext() async {
    if (pickups == null || pickups!.isEmpty) return;

    if (_currentIndex < pickups!.length - 1) {
      await _animationController.reverse();

      if (!mounted) return;

      setState(() => _currentIndex++);
      _animationController.forward();

      await widget.onLocationReached?.call(_currentIndex - 1);
    } else {
      await widget.onLocationReached?.call(_currentIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if required data is available
    if (widget.rideData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show loading state while initializing
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state if initialization failed
    if (_errorMessage != null || pickups == null) {
      return SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              _errorMessage ?? 'Failed to load pickup data',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;

    if (_currentIndex >= pickups!.length) {
      return SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: screenWidth * 0.9,
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'All pickups completed!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
        ),
      );
    }

    final pickup = pickups![_currentIndex];
    final pickupAddress = pickupAddresses![_currentIndex];

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            width: screenWidth * 0.9,
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Column(
                  children: [
                    const Text(
                      'Next Pickup',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "",
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          pickupAddress,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Passenger Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            pickup.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                pickup.rating.toString(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.star,
                                color: Color(0xFFFFC107),
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Address
                      Text(
                        pickup.address,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF333333),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Detour Info
                      Text(
                        '${pickup.detourKm}km detour (+${pickup.detourMin}min)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Price
                      Text(
                        'AUD${pickup.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrived at pickup point
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _moveToNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Passenger Picked Up',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
