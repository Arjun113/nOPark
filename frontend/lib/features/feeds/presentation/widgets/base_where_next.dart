import 'package:flutter/material.dart';
import 'package:nopark/features/trip/entities/user.dart';
import 'package:nopark/features/feeds/presentation/widgets/top_fold.dart';

typedef LocationSelectedCallback = void Function(double lat, double lng);

class WhereNext extends StatefulWidget {
  final User user;
  final List<Map<String, dynamic>> addresses;
  final bool state;
  final LocationSelectedCallback? onLocationSelected;

  const WhereNext({
    super.key,
    required this.user,
    required this.addresses,
    required this.state,
    this.onLocationSelected,
  });

  @override
  State<WhereNext> createState() => WhereNextState();
}

class WhereNextState extends State<WhereNext> with TickerProviderStateMixin {
  OverlayEntry? overlayEntry;
  bool isLifted = false;
  final GlobalKey globalKey = GlobalKey();

  late AnimationController moveAnimationController;
  late AnimationController drawerAnimationController;
  late Animation<double> moveAnimation;

  late FocusNode focusNode;
  late TextEditingController locText;

  @override
  void initState() {
    super.initState();
    moveAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    drawerAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    moveAnimation =
        CurvedAnimation(parent: moveAnimationController, curve: Curves.easeInCubic);
    focusNode = FocusNode();
    locText = TextEditingController();
  }

  void showOverlay() {
    if (!widget.state || overlayEntry != null) return;

    final contextRender = globalKey.currentContext;
    if (contextRender == null) return;

    final renderBox = contextRender.findRenderObject();
    if (renderBox == null || renderBox is! RenderBox) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    overlayEntry = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: removeOverlay,
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: moveAnimation,
                builder: (context, child) {
                  final top = offset.dy -
                      (offset.dy - MediaQuery.of(context).padding.top - 10) *
                          moveAnimation.value;
                  return Positioned(
                    left: offset.dx,
                    width: size.width,
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
                                  topRight: Radius.circular(12)),
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
                                  bottomRight: Radius.circular(12)),
                            ),
                            child: Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Trigger callback
                                  if (widget.onLocationSelected != null) {
                                    widget.onLocationSelected!(
                                        37.4219999, -122.0840575); // example lat/lng
                                  }
                                  removeOverlay();
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
      },
    );

    Overlay.of(context)?.insert(overlayEntry!);

    setState(() {
      isLifted = true;
    });

    // Animate lift + unfold folds
    moveAnimationController.forward().then((_) {
      drawerAnimationController.forward();
      focusNode.requestFocus();
    });
  }

  /// Collapse the overlay with animation
  void removeOverlay({VoidCallback? onComplete}) {
    drawerAnimationController.reverse().then((_) {
      moveAnimationController.reverse().then((_) {
        overlayEntry?.remove();
        overlayEntry = null;
        setState(() {
          isLifted = false;
        });
        if (onComplete != null) onComplete();
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
      onTap: showOverlay,
      child: Opacity(
        opacity: isLifted ? 0 : 1,
        child: Container(
          key: globalKey,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.location_on_outlined),
              SizedBox(width: 8),
              Text("Where to next?", style: TextStyle(fontSize: 20)),
            ],
          ),
        ),
      ),
    );
  }
}
