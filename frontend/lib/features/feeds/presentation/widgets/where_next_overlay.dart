import 'package:flutter/material.dart';
import 'package:nopark/features/feeds/presentation/widgets/top_fold.dart';
import 'package:nopark/features/trip/entities/user.dart';

typedef LocationSelectedCallback =
    void Function(double lat, double lng, String name, String code);

class WhereNextOverlay extends StatefulWidget {
  final User user;
  final List<Map<String, dynamic>> addresses;
  final LocationSelectedCallback? onLocationSelected;
  final VoidCallback? onBack;
  final Offset initialPosition;
  final Size initialSize;

  const WhereNextOverlay({
    super.key,
    required this.user,
    required this.addresses,
    this.onLocationSelected,
    this.onBack,
    required this.initialPosition,
    required this.initialSize,
  });

  @override
  State<WhereNextOverlay> createState() => _WhereNextOverlayState();
}

class _WhereNextOverlayState extends State<WhereNextOverlay>
    with TickerProviderStateMixin {
  late AnimationController moveAnimationController;
  late AnimationController drawerAnimationController;
  late Animation<double> moveAnimation;

  late FocusNode focusNode;
  late TextEditingController locText;

  @override
  void initState() {
    super.initState();
    moveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    drawerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    moveAnimation = CurvedAnimation(
      parent: moveAnimationController,
      curve: Curves.easeInCubic,
    );
    focusNode = FocusNode();
    locText = TextEditingController();

    // Start animation immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      moveAnimationController.forward().then((_) {
        drawerAnimationController.forward();
        focusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    moveAnimationController.dispose();
    drawerAnimationController.dispose();
    locText.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onBack,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: moveAnimation,
            builder: (context, child) {
              final top =
                  widget.initialPosition.dy -
                  (widget.initialPosition.dy -
                          MediaQuery.of(context).padding.top -
                          10) *
                      moveAnimation.value;

              return Positioned(
                left: widget.initialPosition.dx,
                width: widget.initialSize.width,
                top: top,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top fold
                    SizeTransition(
                      sizeFactor: CurvedAnimation(
                        parent: drawerAnimationController,
                        curve: Curves.easeOutCubic,
                      ),
                      axis: Axis.vertical,
                      child: Container(
                        height: 65,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: TopFoldWhereNext(user: widget.user),
                      ),
                    ),

                    // Middle lifted widget
                    Material(
                      borderRadius: BorderRadius.zero,
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            if (locText.text.isEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Where to next?",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            TextField(
                              controller: locText,
                              focusNode: focusNode,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.all(5),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom fold with Confirm button
                    SizeTransition(
                      sizeFactor: CurvedAnimation(
                        parent: drawerAnimationController,
                        curve: Curves.easeOutCubic,
                      ),
                      axis: Axis.vertical,
                      child: Container(
                        height: 300, // Increased height for multiple results
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: locations.length,
                          itemBuilder: (context, index) {
                            final location = locations[index];

                            final name =
                                location['name'] as String? ?? 'Unknown';
                            final code = location['code'] as String? ?? '';
                            final lat = location['latitude'] as double;
                            final lng = location['longitude'] as double;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ElevatedButton(
                                onPressed: () {
                                  widget.onLocationSelected?.call(
                                    lat,
                                    lng,
                                    name,
                                    code,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  alignment: Alignment.centerLeft,
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$code — ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> locations = [
  {
    'name': 'Clayton Campus',
    'code': 'CL',
    'latitude': -37.9078,
    'longitude': 145.1339,
  },
  {
    'name': 'Caulfield Campus',
    'code': 'CA',
    'latitude': -37.8768,
    'longitude': 145.0458,
  },
  {
    'name': "Peninsula Campus",
    "code": "PE",
    'latitude': -38.1520,
    'longitude': 145.1360,
  },
  {
    'name': "Law Chambers",
    "code": "LA",
    "latitude": -37.8145,
    'longitude': 144.9560,
  },
];
