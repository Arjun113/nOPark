// Purpose: Just the top fold

import 'package:flutter/material.dart';

import '../../../trip/entities/user.dart';

class TopFoldWhereNext extends StatelessWidget {
  final User user;

  const TopFoldWhereNext({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Row (
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Hello ${user.firstName}",
              style: const TextStyle(
                  fontSize: 22,
                  fontFamily: 'Roboto',
                  color: Colors.black,
                  fontWeight: FontWeight.w500
              ),
            ),
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(user.imageUrl),
            ),
          ],
        ),
    );
  }
}