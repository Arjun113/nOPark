import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:nopark/logic/network/dio_client.dart';

class PickupInfo {
  final String name;
  final double rating;
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
  final int rideID;
  final Stream<int>? locationStream;
  final Function(int)? onLocationReached;

  const PickupSequenceWidget({
    super.key,
    required this.rideID,
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
  late List<PickupInfo> pickups;

  @override
  void initState() async {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // TODO: Populate pickup
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _moveToNext() {
    if (_currentIndex < pickups.length - 1) {
      _animationController.reverse().then((_) {
        setState(() {
          _currentIndex++;
        });
        _animationController.forward();
        widget.onLocationReached?.call(_currentIndex - 1);
      });
    } else {
      widget.onLocationReached?.call(_currentIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (_currentIndex >= pickups.length) {
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

    final pickup = pickups[_currentIndex];

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
                            pickup.destinationCode,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          pickup.destination,
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
                    'Passenger Picked Up' ,
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
