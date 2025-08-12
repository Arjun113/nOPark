// Purpose: fullscreen map

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nopark/constants/api_uris.dart';
import 'package:nopark/logic/location/loc_stream.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class FullScreenMap extends StatelessWidget {
  final StreamSubscription<Position> locations = locationStream;

  FullScreenMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(-37.907803, 145.133957),
          initialZoom: 5
        ),
        children: [
          TileLayer(
            urlTemplate: openStreetMapUri,
            userAgentPackageName: openStreetMapUserAgent,
          ),
          RichAttributionWidget( // Include a stylish prebuilt attribution widget that meets all requirments
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap contributors',
                onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')), // (external)
              ),
              // Also add images...
            ],
          ),
        ],
      ),
    );
  }
}