import 'package:flutter/material.dart';

class RideCompletionWidget extends StatefulWidget {
  final String riderName;
  final String price;
  final double initialRating;
  final VoidCallback? moveToZero;

  const RideCompletionWidget({
    super.key,
    required this.riderName,
    required this.price,
    this.initialRating = 0.0,
    required this.moveToZero,
  });

  @override
  State<RideCompletionWidget> createState() => _RideCompletionWidgetState();
}

class _RideCompletionWidgetState extends State<RideCompletionWidget> {
  double _currentRating = 0.0;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  void _updateRating(double rating) {
    setState(() {
      _currentRating = rating;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 320,
        height: 350,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Title
              const Text(
                'Ride Completed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Rider info row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.riderName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _currentRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                    ],
                  ),
                ],
              ),

              // Price
              Text(
                widget.price,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 16),

              // "How was the ride?" text
              const Text(
                'How was the ride?',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 12),

              // Star rating
              StarRating(
                rating: _currentRating,
                onRatingChanged: _updateRating,
              ),

              // OK Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.moveToZero,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StarRating extends StatefulWidget {
  final double rating;
  final Function(double) onRatingChanged;
  final int maxRating;

  const StarRating({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.maxRating = 5,
  });

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        return GestureDetector(
          onTapDown: (details) {
            // Calculate if tap was on left or right half of star
            final RenderBox box = context.findRenderObject() as RenderBox;
            final localPosition = box.globalToLocal(details.globalPosition);
            final starWidth = 40.0; // Width of each star container
            final starIndex = (localPosition.dx / starWidth).floor();
            final positionInStar = (localPosition.dx % starWidth) / starWidth;

            double newRating;
            if (positionInStar < 0.5) {
              newRating = starIndex + 0.5;
            } else {
              newRating = starIndex + 1.0;
            }

            // Ensure rating is within bounds
            newRating = newRating.clamp(0.5, widget.maxRating.toDouble());
            widget.onRatingChanged(newRating);
          },
          child: Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(4),
            child: _buildStar(index + 1),
          ),
        );
      }),
    );
  }

  Widget _buildStar(int starNumber) {
    double difference = widget.rating - starNumber + 1;

    if (difference >= 1.0) {
      // Full star
      return const Icon(Icons.star, color: Colors.amber, size: 32);
    } else if (difference >= 0.5) {
      // Half star
      return Stack(
        children: [
          const Icon(Icons.star_border, color: Colors.amber, size: 32),
          ClipRect(
            clipper: HalfStarClipper(),
            child: const Icon(Icons.star, color: Colors.amber, size: 32),
          ),
        ],
      );
    } else {
      // Empty star
      return const Icon(Icons.star_border, color: Colors.amber, size: 32);
    }
  }
}

class HalfStarClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}
