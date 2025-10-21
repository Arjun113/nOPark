import 'package:flutter/material.dart';

class BidData {
  final String name;
  final int rating;
  final String address;
  final String distance;
  final String bid;

  BidData({
    required this.name,
    required this.rating,
    required this.address,
    required this.distance,
    required this.bid,
  });
}

class BidItem extends StatelessWidget {
  final BidData bidData;

  const BidItem({super.key, required this.bidData});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bidData.name,
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    Text(
                      bidData.rating.toString(),
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    const Icon(Icons.star, color: Colors.amber, size: 16.0),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text(
                  bidData.address,
                  style: const TextStyle(fontSize: 14.0, color: Colors.black54),
                ),
                const SizedBox(height: 2.0),
                Text(
                  bidData.distance,
                  style: const TextStyle(fontSize: 12.0, color: Colors.black45),
                ),
              ],
            ),
          ),
          Text(
            bidData.bid,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class TripChooseWidget extends StatelessWidget {
  final String? toCampusCode;
  final String campusName;
  final List<BidData> bids;
  final double height;

  const TripChooseWidget({
    super.key,
    this.toCampusCode,
    required this.campusName,
    required this.bids,
    this.height = 400.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                toCampusCode != null
                    ? Row(
                      children: [
                        Text(
                          toCampusCode!,
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Text(
                          campusName,
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.normal,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    )
                    : Center(
                      child: Text(
                        campusName,
                        style: const TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                    ),
          ),
          // Scrollable list
          Expanded(
            child: ListView.builder(
              itemCount: bids.length,
              itemBuilder: (context, index) {
                return BidItem(bidData: bids[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
