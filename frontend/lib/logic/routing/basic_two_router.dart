import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:nopark/constants/secrets.dart';
import 'package:nopark/logic/error/failures.dart';

class RoutingService {
  // OpenRouteService API - free tier allows 2000 requests/day
  static const String _baseUrl = 'https://api.openrouteservice.org/v2/directions';

  // You need to get a free API key from: https://openrouteservice.org/dev/#/signup
  // Replace this with your actual API key
  static final String _apiKey = routingTrialApi;

  /// Gets a route between two points using OpenRouteService
  ///
  /// [start] - Starting point coordinates
  /// [destination] - Destination point coordinates
  /// [profile] - Travel profile: 'driving-car', 'walking', 'cycling-regular', etc.
  ///
  /// Returns a List<LatLng> representing the route points, or null if failed
  static Future<List<LatLng>?> getRoute(
      LatLng? start,
      LatLng? destination, {
        String profile = 'driving-car',
      }) async {
    try {

      if (start == null || destination == null) {
        throw InputFailure("Both start and destination must be non-null");
      }

      // Construct the URL
      final url = Uri.parse('$_baseUrl/$profile');

      // Prepare the request body
      final requestBody = {
        'coordinates': [
          [start.longitude, start.latitude],    // Start point [lng, lat]
          [destination.longitude, destination.latitude]  // End point [lng, lat]
        ],
        'format': 'json',
        'geometry': 'true',
        'instructions': 'false',  // We don't need turn-by-turn instructions
      };

      // Make the POST request
      final response = await http.post(
        url,
        headers: {
          'Authorization': _apiKey,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Extract the route geometry
        final routes = data['routes'] as List;
        if (routes.isEmpty) {
          print('No routes found');
          return null;
        }

        final geometry = routes[0]['geometry'];

        // Decode the polyline geometry
        final coordinates = _decodePolyline(geometry);

        return coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();

      } else {
        print('Routing API error: ${response.statusCode} - ${response.body}');
        return null;
      }

    } catch (e) {
      print('Error getting route: $e');
      return null;
    }
  }


  /// Decodes a polyline string into a list of coordinates
  /// This is used when the API returns encoded polyline geometry
  static List<List<double>> _decodePolyline(dynamic geometry) {
    if (geometry is String) {
      // If geometry is an encoded polyline string, decode it
      return _decodePolylineString(geometry);
    } else if (geometry is List) {
      // If geometry is already a list of coordinates, convert to List<List<double>>
      return geometry.map<List<double>>((coord) => [
        (coord[0] as num).toDouble(),
        (coord[1] as num).toDouble()
      ]).toList();
    } else {
      throw Exception('Unknown geometry format');
    }
  }

  /// Decodes a polyline encoded string
  static List<List<double>> _decodePolylineString(String encoded) {
    List<List<double>> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add([lng / 1E5, lat / 1E5]);
    }

    return points;
  }

  /// Gets route with additional information (distance, duration)
  static Future<RouteInfo?> getDetailedRoute(
      LatLng start,
      LatLng destination, {
        String profile = 'driving-car',
      }) async {
    try {
      final url = Uri.parse('$_baseUrl/$profile');

      final requestBody = {
        'coordinates': [
          [start.longitude, start.latitude],
          [destination.longitude, destination.latitude]
        ],
        'format': 'json',
        'geometry': 'true',
        'instructions': 'true',
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': _apiKey,
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;

        if (routes.isEmpty) return null;

        final route = routes[0];
        final summary = route['summary'];
        final geometry = route['geometry'];

        final coordinates = _decodePolyline(geometry);
        final points = coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();

        return RouteInfo(
          points: points,
          distance: summary['distance'].toDouble(), // meters
          duration: summary['duration'].toDouble(), // seconds
        );

      } else {
        print('Routing API error: ${response.statusCode}');
        return null;
      }

    } catch (e) {
      print('Error getting detailed route: $e');
      return null;
    }
  }
}

/// Class to hold route information
class RouteInfo {
  final List<LatLng> points;
  final double distance; // in meters
  final double duration; // in seconds

  RouteInfo({
    required this.points,
    required this.distance,
    required this.duration,
  });

  /// Get distance in kilometers
  double get distanceKm => distance / 1000;

  /// Get duration in minutes
  double get durationMinutes => duration / 60;

  /// Get formatted distance string
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.round()}m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Get formatted duration string
  String get formattedDuration {
    final minutes = (duration / 60).round();
    if (minutes < 60) {
      return '${minutes}min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}min';
    }
  }
}