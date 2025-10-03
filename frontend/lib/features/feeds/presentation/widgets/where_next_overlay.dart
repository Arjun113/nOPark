import 'package:flutter/material.dart';
import 'package:nopark/features/trip/entities/user.dart';
import 'package:nopark/features/feeds/presentation/widgets/top_fold.dart';

typedef LocationSelectedCallback = void Function(double lat, double lng);

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
              final top = widget.initialPosition.dy -
                  (widget.initialPosition.dy - MediaQuery.of(context).padding.top - 10) *
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
                                  Icon(Icons.location_on_outlined,
                                      color: Colors.grey),
                                  SizedBox(width: 8),
                                  Text(
                                    "Where to next?",
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 18),
                                  ),
                                ],
                              ),
                            TextField(
                              controller: locText,
                              focusNode: focusNode,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 18),
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
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: () {
                              if (widget.onLocationSelected != null) {
                                widget.onLocationSelected!(
                                    -37.840935, 144.946457); // example lat/lng
                              }
                            },
                            child: const Text("Confirm Location"),
                          ),
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