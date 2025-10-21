import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nopark/features/feeds/datamodels/data_controller.dart';
import 'package:nopark/features/feeds/presentation/widgets/full_screen_map.dart';
import 'package:nopark/logic/network/dio_client.dart';

/// CRON job to maintain polyline, other users, etc
/// Has access to internet to be able to poll for current location
void maintainMap (DataController rideDataShare) {
  Timer.periodic(Duration(seconds: 5), (time) async {


    /// Part 1: if there exists a current ride, go into passenger,
    /// Fetch the driver ID, poll backend for its current location,
    /// And set it as "another location"

    if (rideDataShare.getCurrentPassengerRideProposal() != null) {
      final current_polyline = rideDataShare.getCurrentPassengerRideProposal()!.polyline;
      final current_driver_id = rideDataShare.getCurrentPassengerRideProposal()!.driverID;
      final current_destination = rideDataShare.getCurrentDestination();

      // Update polyline
      rideDataShare.setPolyline(current_polyline);
      // Update destination marker
      rideDataShare.addDestinationMarker(MapMarker(position: LatLng(current_destination!.lat, current_destination.long)));

      // Fetch current driver location from server and update it
      try {
        final driver_data_package = await DioClient().client.get(
          '/accounts/${current_driver_id}',
          data: {}
        );

        final location_response = LatLng(driver_data_package.data['current_latitude'], driver_data_package.data['current_longitude']);

        rideDataShare.addNewOtherLocation(location_response, current_driver_id);
      }
      catch (e) {
        debugPrint("error accessing driver location: $e");
      }
    }


    /// Part 2: if getdriverreceivedproposaldetails and getdriveracceptedproposals are non null
    /// We can use the list to fetch current passenger locations

    if (rideDataShare.getDriverReceivedProposalDetails() != null && rideDataShare.getDriverAcceptedProposals() != null) {
      // For every ride that driver received, check if it was accepted
      for (var ride in rideDataShare.getDriverReceivedProposalDetails()!) {
        if (rideDataShare.getDriverAcceptedProposals()!.contains(ride.proposalID)) {
          // Fetch current passenger location
          try {
            final passenger_data_package = await DioClient().client.get(
                '/accounts/${ride.passengerID}',
                data: {}
            );

            final location_response = LatLng(passenger_data_package.data['current_latitude'], passenger_data_package.data['current_longitude']);

            rideDataShare.addNewOtherLocation(location_response, ride.passengerID);
          }
          catch (e) {
            debugPrint("error accessing passenger location: $e");
          }
        }
      }
    }
  });
}