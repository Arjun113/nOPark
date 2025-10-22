// Purpose: fullscreen map with multiple markers and route support

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:nopark/constants/api_uris.dart';
import 'package:nopark/features/feeds/datamodels/data_controller.dart';
import 'package:nopark/logic/location/loc_perms.dart';
import 'package:nopark/logic/location/loc_stream.dart';
import 'package:nopark/logic/location/loc_updater.dart';
import 'package:url_launcher/url_launcher.dart';

// Custom marker class to hold marker data
class MapMarker {
  final LatLng position;
  final String? label;
  final double width;
  final double height;

  const MapMarker({
    required this.position,
    this.label,
    this.width = 30.0,
    this.height = 30.0,
  });
}

class FullScreenMap extends StatefulWidget {
  final LatLng? initialCenter;
  final double initialZoom;
  final bool showUserLocation;
  final DataController rideDataShare;
  final String userType;

  const FullScreenMap({
    super.key,
    this.initialCenter,
    required this.rideDataShare,
    required this.userType,
    this.initialZoom = 15.0,
    this.showUserLocation = true,
  });

  @override
  State<FullScreenMap> createState() => FullScreenMapState();
}

class FullScreenMapState extends State<FullScreenMap> {
  StreamSubscription<Position>? _locationSubscription;
  final MapController _mapController = MapController();

  LatLng? currentLocation;
  LatLng _mapCenter = const LatLng(
    -37.907803,
    145.133957,
  ); // Default Melbourne location

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

    LocationService().startLocationUpdates();
  }

  void _startLocationTracking() {
    _locationSubscription = locationStream.listen(
      (Position position) {
        if (mounted) {
          setState(() {
            currentLocation = LatLng(position.latitude, position.longitude);
            widget.rideDataShare.setCurrentLocation(
              LatLng(position.latitude, position.longitude),
            );
          });

          // Optional: Auto-center map on user location
          _mapController.move(currentLocation!, _mapController.camera.zoom);
        }
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
      cancelOnError: false, // Keep the stream active even after errors
    );
  }

  void _centerOnUserLocation() {
    if (currentLocation != null) {
      _mapController.move(currentLocation!, 16.0);
    }
  }

  // Method to fit bounds to show both user location and destination
  void fitBoundsToShowAllMarkers() {
    if (currentLocation == null &&
        widget.rideDataShare.getDestinationMarkers().isEmpty) {
      return;
    }

    List<LatLng> points = [];

    if (currentLocation != null) {
      points.add(currentLocation!);
    }

    for (var marker in widget.rideDataShare.getRoutePoints()) {
      points.add(marker);
    }

    if (points.isEmpty) return;

    // Calculate bounds
    double minLat = points
        .map((p) => p.latitude)
        .reduce((a, b) => a < b ? a : b);
    double maxLat = points
        .map((p) => p.latitude)
        .reduce((a, b) => a > b ? a : b);
    double minLng = points
        .map((p) => p.longitude)
        .reduce((a, b) => a < b ? a : b);
    double maxLng = points
        .map((p) => p.longitude)
        .reduce((a, b) => a > b ? a : b);

    // Add some padding
    double latPadding = (maxLat - minLat) * 0.4;
    double lngPadding = (maxLng - minLng) * 0.4;

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(minLat - latPadding, minLng - lngPadding),
          LatLng(maxLat + latPadding, maxLng + lngPadding),
        ),
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  // Public method to update map center (can be called from parent widgets)
  void updateMapCenter(double lat, double lng) {
    final newLocation = LatLng(lat, lng);
    setState(() {
      _mapCenter = newLocation;
    });
    _mapController.move(newLocation, 15.0);
  }

  // Helper method to build all markers
  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // User location marker
    if (currentLocation != null && widget.showUserLocation) {
      markers.add(
        Marker(
          point: currentLocation!,
          width: 20.0,
          height: 20.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Destination markers
    for (var marker in widget.rideDataShare.getDestinationMarkers()) {
      markers.add(
        Marker(
          point: marker.position,
          width: marker.width,
          height: marker.height,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Other users
    for (var otherUser in widget.rideDataShare.getOtherPeopleLocation()) {
      if (widget.userType == 'Passenger') {
        markers.add(
          Marker(
            point: otherUser['location'],
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_car,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        );
      } else {
        markers.add(
          Marker(
            point: otherUser['location'],
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_pin_circle_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.rideDataShare,
      builder: ((context, _) {
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

                  // Route polyline layer
                  if (widget.rideDataShare.getRoutePoints().isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: widget.rideDataShare.getRoutePoints(),
                          strokeWidth: 4.0,
                          color: Colors.blue,
                          pattern: StrokePattern.solid(),
                        ),
                      ],
                    ),

                  // All markers layer
                  MarkerLayer(markers: _buildMarkers()),

                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap:
                            () => launchUrl(
                              Uri.parse('https://openstreetmap.org/copyright'),
                            ),
                      ),
                    ],
                  ),
                ],
              ),

              // Floating action buttons
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fit bounds button (show both markers)
                    if (widget.rideDataShare
                            .getDestinationMarkers()
                            .isNotEmpty &&
                        currentLocation != null)
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                        onPressed: fitBoundsToShowAllMarkers,
                        heroTag: "fit_bounds",
                        child: const Icon(Icons.fit_screen),
                      ),

                    const SizedBox(height: 8),

                    // Center on user location button
                    if (widget.showUserLocation && currentLocation != null)
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        onPressed: _centerOnUserLocation,
                        heroTag: "center_location",
                        child: const Icon(Icons.my_location),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
