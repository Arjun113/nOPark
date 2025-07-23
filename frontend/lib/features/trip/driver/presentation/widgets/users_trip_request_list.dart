// Purpose: Aggregate multiple of these

import 'package:flutter/material.dart';
import 'package:nopark/features/profiles/presentation/widgets/address_scroller.dart';
import 'package:nopark/features/trip/driver/presentation/widgets/single_user_trip_request.dart';
import 'multi_trip_request_controller.dart';

class AddressCardList extends StatefulWidget {
  final MultiAddressCardController controller;
  final List<AddressCardData> addresses;
  final List<double> detours;
  final List<String> users;
  final List<double> costs;
  final List<double> ratings;

  const AddressCardList({
    super.key,
    required this.controller,
    required this.addresses,
    required this.costs,
    required this.detours,
    required this.users,
    required this.ratings
  });

  @override
  State<AddressCardList> createState() => _AddressCardListState();
}

class _AddressCardListState extends State<AddressCardList> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(widget.addresses.length, (index) {
          final addr = widget.addresses[index];
          final isSelected = widget.controller.isSelected(index);
          final user = widget.users[index];
          final rating = widget.ratings[index];
          final detour = widget.detours[index];
          final cost = widget.costs[index];

          return AddressCard(
            name: user,
            rating: rating,
            address: addr,
            detourInfo: detour,
            cost: cost,
            selected: isSelected,
            onTap: () => widget.controller.toggle(index),
          );
        }),
      ),
    );
  }
}