import 'package:flutter/material.dart';
import '../../../trip/entities/user.dart';

class WhereNext extends StatefulWidget {
  final User user;
  final List<Map<String, dynamic>> addresses;
  final bool state;

  const WhereNext({super.key, required this.user, required this.addresses, required this.state});

  @override
  State<StatefulWidget> createState() => WhereNextState();
}

class WhereNextState extends State<WhereNext> with TickerProviderStateMixin {
  OverlayEntry? overlayEntry;
  bool isLifted = false;
  final GlobalKey globalKey = GlobalKey();
  late AnimationController moveAnimationController;
  late AnimationController drawerAnimationController;
  late Animation<double> moveAnimation;

  @override
  void initState() {
    super.initState();
    moveAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    drawerAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    moveAnimation = CurvedAnimation(parent: moveAnimationController, curve: Curves.easeInCubic);
  }

  void showOverlay() {
    if (!widget.state) return;

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
                  // Move the widget from its original position up to near top
                  final top = offset.dy - (offset.dy - MediaQuery.of(context).padding.top - 10) * moveAnimation.value;

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
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),

                        // Lifted widget (middle)
                        Material(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
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

                        // Bottom fold
                        SizeTransition(
                          sizeFactor: CurvedAnimation(
                            parent: drawerAnimationController,
                            curve: Curves.easeOutCubic,
                          ),
                          axis: Axis.vertical,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
            ],
          ),
        );
      },
    );

    Overlay.of(context)?.insert(overlayEntry!);

    setState(() {
      isLifted = true;
    });

    // Animate lift first, then unfold folds
    moveAnimationController.forward().then((_) {
      drawerAnimationController.forward();
    });
  }

  void removeOverlay() {
    drawerAnimationController.reverse().then((_) {
      moveAnimationController.reverse().then((_) {
        overlayEntry?.remove();
        overlayEntry = null;
        setState(() {
          isLifted = false;
        });
      });
    });
  }

  @override
  void dispose() {
    moveAnimationController.dispose();
    drawerAnimationController.dispose();
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
            color: Colors.grey.shade200,
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
