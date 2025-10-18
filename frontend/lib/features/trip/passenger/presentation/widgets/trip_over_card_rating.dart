import 'package:flutter/material.dart';

class RideInfo {
  final String riderName;
  final double riderPrice;
  double rating;
  String comment;

  RideInfo({
    required this.riderName,
    required this.riderPrice,
    this.rating = 0.0,
    this.comment = ""
  });
}

class RideCompletionWidget extends StatefulWidget {
  final List<RideInfo> riders;
  final VoidCallback? moveToZero;

  const RideCompletionWidget({
    super.key,
    required this.riders,
    required this.moveToZero,
  });

  @override
  State<RideCompletionWidget> createState() => _RideCompletionWidgetState();
}

class _RideCompletionWidgetState extends State<RideCompletionWidget> {
  late PageController _pageController;
  int _currentPage = 0;
  late List<TextEditingController> _commentControllers;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _commentControllers = widget.riders
        .map((rider) => TextEditingController(text: rider.comment))
        .toList();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _commentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateRating(int index, double rating) {
    setState(() {
      widget.riders[index].rating = rating;
    });
  }

  void _updateComment(int index, String comment) {
    widget.riders[index].comment = comment;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 320,
        height: 480,
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Title
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text(
                'Ride Completed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Page indicator dots
            if (widget.riders.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.riders.length,
                      (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.blue
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            if (widget.riders.length > 1) const SizedBox(height: 16),

            // Scrollable rider cards
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: widget.riders.length,
                itemBuilder: (context, index) {
                  final rider = widget.riders[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Rider info row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  rider.riderName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: [
                                  Text(
                                    rider.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 18),
                                ],
                              ),
                            ],
                          ),

                          // Price
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              rider.riderPrice.toString(),
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black54),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // "How was the ride?" text
                          const Text(
                            'How was the ride?',
                            style:
                            TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                          const SizedBox(height: 12),

                          // Star rating
                          StarRating(
                            rating: rider.rating,
                            onRatingChanged: (rating) =>
                                _updateRating(index, rating),
                          ),
                          const SizedBox(height: 20),

                          // Comment text field
                          TextField(
                            controller: _commentControllers[index],
                            onChanged: (value) => _updateComment(index, value),
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Add a comment (optional)',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.blue),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // OK Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
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
            ),
          ],
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