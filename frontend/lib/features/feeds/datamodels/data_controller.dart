import 'package:flutter/material.dart';
import 'package:nopark/features/feeds/datamodels/passenger/ride_proposal.dart';
import 'package:nopark/features/feeds/datamodels/passenger/ride_request_response.dart';

import '../../trip/driver/presentation/widgets/ride_options_screen.dart';
import '../../trip/entities/location.dart';
import '../../trip/passenger/presentation/widgets/trip_over_card_rating.dart';
import 'driver/user_data.dart';

class DataController extends ChangeNotifier {
  Location? destination;
  RideRequestResponse? rideReqResp;
  int? rideProposalId;
  double? initialCompensation;
  String? destinationString;
  String? startingString;
  RideProposal? rideProposal;
  UserResponse? driverData;
  List<int>? driverAcceptedProposals;
  int? finalRideId;
  List<RideOption>? driverRideProposals;

  Location? getCurrentDestination() => destination;
  RideRequestResponse? getRideReqResp() => rideReqResp;
  int? getCurrentRideProposalID() => rideProposalId;
  double? getCurrentRideInitialCompensation() => initialCompensation;
  String? getCurrentDestinationString() => destinationString;
  String? getCurrentStartingString() => startingString;
  RideProposal? getCurrentPassengerRideProposal() => rideProposal;
  UserResponse? getCurrentUserResponse() => driverData;
  List<int>? getDriverAcceptedProposals() => driverAcceptedProposals;
  int? getFinalRideId() => finalRideId;
  List<RideOption>? getDriverReceivedProposalDetails() => driverRideProposals;

  void setCurrentDestination(Location destination) {
    this.destination = destination;
    notifyListeners();
  }

  void setRideReqResp(RideRequestResponse rideResponse) {
    rideReqResp = rideResponse;
    notifyListeners();
  }

  void setCurrentRideProposalID(int rideProposalID) {
    // ignore: unnecessary_this
    this.rideProposalId = rideProposalID;
    notifyListeners();
  }

  void setCurrentRideInitialCompensation(double newInitialCompensation) {
    initialCompensation = newInitialCompensation;
    notifyListeners();
  }

  void setCurrentDestinationString(String newDestinationString) {
    destinationString = newDestinationString;
    notifyListeners();
  }

  void setCurrentStartingString(String newStartingString) {
    startingString = newStartingString;
    notifyListeners();
  }

  void setCurrentPassengerRideProposal(RideProposal newProposal) {
    rideProposal = newProposal;
    notifyListeners();
  }

  void setCurrentUserResponse(UserResponse newResponse) {
    driverData = newResponse;
    notifyListeners();
  }

  void setDriverAcceptedProposals(List<int> proposals) {
    driverAcceptedProposals = proposals;
    notifyListeners();
  }

  void setFinalRideId(int newRideId) {
    finalRideId = newRideId;
    notifyListeners();
  }

  void setDriverReceivedProposalDetails(List<RideOption> proposals) {
    debugPrint("📝 setDriverReceivedProposalDetails called");
    debugPrint("   Input length: ${proposals.length}");
    debugPrint("   DataController instance: ${this.hashCode}");

    driverRideProposals = proposals;

    debugPrint("   After set, length: ${driverRideProposals?.length ?? 0}");

    // If using state management, notify listeners
    notifyListeners(); // or whatever your pattern is
  }

  List<RideInfo>? getCurrentRiderInfo(String yourRole) {
    if (yourRole == 'Passenger') {
      // Check if required data exists
      if (driverData == null || rideReqResp == null || rideProposal == null) {
        return null;
      }

      // Send the driver's details
      return [
        RideInfo(
          riderName: driverData!.firstName + driverData!.lastName,
          riderPrice: rideReqResp!.initialCompensation,
          riderID: rideProposal!.driverID,
        ),
      ];
    } else {
      // Check if required data exists

      debugPrint("getting to start of driver fetch");
      // Use null-safe operators
      final proposals = driverRideProposals;
      final accepted = driverAcceptedProposals;

      if (proposals == null) {
        debugPrint("⚠️ No ride proposals");
        return null;
      }

      if (accepted == null) {
        debugPrint("⚠️ No accepted proposals");
        return null;
      }

      List<RideInfo> passengerInfos = [];
      for (var passenger in driverRideProposals!) {
        debugPrint("at passenger fetch");
        if (driverAcceptedProposals!.contains(passenger.proposalID)) {
          passengerInfos.add(
            RideInfo(
              riderName: passenger.name,
              riderPrice: passenger.price,
              riderID: passenger.passengerID,
            ),
          );
        }
      }

      debugPrint(passengerInfos.toString());
      return passengerInfos;
    }
  }

  void clearForNextRide() {
    driverRideProposals = null;
    driverAcceptedProposals = null;
    driverData = null;
    destinationString = null;
    destination = null;
    finalRideId = null;
    initialCompensation = null;
    rideProposal = null;
    rideProposalId = null;
    rideReqResp = null;
    startingString = null;
  }
}
