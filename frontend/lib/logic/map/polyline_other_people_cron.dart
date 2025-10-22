import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nopark/features/feeds/datamodels/data_controller.dart';
import 'package:nopark/features/feeds/presentation/widgets/full_screen_map.dart';
import 'package:nopark/logic/network/dio_client.dart';

/// CRON job to maintain polyline, other users, etc
/// Has access to internet to be able to poll for current location
void maintainMap(DataController rideDataShare, GlobalKey<FullScreenMapState> mapController) {
  Timer.periodic(Duration(seconds: 10), (time) async {
    /// Part 1: if there exists a current ride, go into passenger,
    /// Fetch the driver ID, poll backend for its current location,
    /// And set it as "another location"

    if (rideDataShare.getCurrentPassengerRideProposal() != null) {
      final currentPolyline =
          rideDataShare.getCurrentPassengerRideProposal()!.polyline;
      final currentDriverId =
          rideDataShare.getCurrentPassengerRideProposal()!.driverID;
      final currentDestination = rideDataShare.getCurrentDestination();

      // Update polyline
      rideDataShare.setPolyline(currentPolyline);
      mapController.currentState?.fitBoundsToShowAllMarkers();
      // Update destination marker
      rideDataShare.addDestinationMarker(
        MapMarker(
          position: LatLng(currentDestination!.lat, currentDestination.long),
        ),
      );

      // Fetch current driver location from server and update it
      try {
        final driverDataPackage = await DioClient().client.get(
          '/accounts/$currentDriverId',
          data: {},
        );

        final locationResponse = LatLng(
          driverDataPackage.data['current_latitude'],
          driverDataPackage.data['current_longitude'],
        );

        rideDataShare.addNewOtherLocation(locationResponse, currentDriverId);
      } catch (e) {
        debugPrint("error accessing driver location: $e");
      }
    }

    /// Part 2: if getdriverreceivedproposaldetails and getdriveracceptedproposals are non null
    /// We can use the list to fetch current passenger locations

    if (rideDataShare.getDriverReceivedProposalDetails() != null &&
        rideDataShare.getDriverAcceptedProposals() != null) {
      // All proposals have the same endpoint
      final currentDestination = rideDataShare.getCurrentDestination();
      rideDataShare.addDestinationMarker(
        MapMarker(
          position: LatLng(currentDestination!.lat, currentDestination.long),
        ),
      );

      // For every ride that driver received, check if it was accepted
      for (var ride in rideDataShare.getDriverReceivedProposalDetails()!) {
        if (rideDataShare.getDriverAcceptedProposals()!.contains(
          ride.proposalID,
        )) {
          // Fetch current passenger location
          try {
            final passengerDataPackage = await DioClient().client.get(
              '/accounts/${ride.passengerID}',
              data: {},
            );

            final locationResponse = LatLng(
              passengerDataPackage.data['current_latitude'],
              passengerDataPackage.data['current_longitude'],
            );

            rideDataShare.addNewOtherLocation(
              locationResponse,
              ride.passengerID,
            );
          } catch (e) {
            debugPrint("error accessing passenger location: $e");
          }
        }
      }
    }
  });

  /// Part 3: Update route polyline every 10 seconds
  Timer.periodic(Duration(seconds: 10), (time) async {
    if (rideDataShare.getFinalRideId() != null) {
      // Get route data from backend
      try {
        final rideRouteData = await DioClient().client.get(
          '/rides/route?ride_id=${rideDataShare.getFinalRideId()}',
          data: {},
        );

        // Assign polyline
        rideDataShare.setPolyline(rideRouteData.data['polyline']);
        mapController.currentState?.fitBoundsToShowAllMarkers();
      } catch (e) {
        debugPrint("Error updating route polyline");
      }
    }
  });
}
