// Purpose: fullscreen map

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nopark/constants/api_uris.dart';
import 'package:nopark/logic/location/loc_perms.dart';
import 'package:nopark/logic/location/loc_stream.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class FullScreenMap extends StatefulWidget {
  final LatLng? initialCenter;
  final double initialZoom;
  final bool showUserLocation;

  const FullScreenMap({
    super.key,
    this.initialCenter,
    this.initialZoom = 15.0,
    this.showUserLocation = true,
  });

  @override
  State<FullScreenMap> createState() => _FullScreenMapState();
}

class _FullScreenMapState extends State<FullScreenMap> {
  StreamSubscription<Position>? _locationSubscription;
  final MapController _mapController = MapController();

  LatLng? _currentLocation;
  LatLng _mapCenter = const LatLng(-37.907803, 145.133957); // Default Melbourne location

  @override
  void initState() {
    super.initState();

    requestLocationPermission();

    // Set initial center if provided
    if (widget.initialCenter != null) {
      _mapCenter = widget.initialCenter!;
    }

    // Start listening to location updates if enabled
    if (widget.showUserLocation) {
      _startLocationTracking();
    }
  }

  void _startLocationTracking() {



    _locationSubscription = locationStream.listen(
          (Position position) {
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
          });

          // Optional: Auto-center map on user location
          _mapController.move(_currentLocation!, _mapController.camera.zoom);
        }
      },
      onError: (error) {
        // Handle location stream errors
        debugPrint('Location stream error: $error');
      },
    );
  }

  void _centerOnUserLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 16.0);
    }
  }

  // Public method to update map center (can be called from parent widgets)
  void updateMapCenter(double lat, double lng) {
    final newLocation = LatLng(lat, lng);
    setState(() {
      _mapCenter = newLocation;
    });
    _mapController.move(newLocation, 15.0);
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: widget.initialZoom,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: openStreetMapUri,
                userAgentPackageName: openStreetMapUserAgent,
              ),

              // User location marker
              if (_currentLocation != null && widget.showUserLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 20.0,
                      height: 20.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
                  ),
                ],
              ),
            ],
          ),

          // Floating action button to center on user location
          if (widget.showUserLocation && _currentLocation != null)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                onPressed: _centerOnUserLocation,
                child: const Icon(Icons.my_location),
              ),
            ),
        ],
      ),
    );
  }
}