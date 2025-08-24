import 'package:flutter/material.dart';

enum DriverSearchState { loading, found }

class DriverSearchPopup extends StatefulWidget {
  final DriverSearchState state;
  final String? driverName;
  final String? driverImage; // URL or asset path
  final VoidCallback? onCancel;
  final VoidCallback? onDriverFound;

  const DriverSearchPopup({
    Key? key,
    required this.state,
    this.driverName,
    this.driverImage,
    this.onCancel,
    this.onDriverFound,
  }) : super(key: key);

  @override
  State<DriverSearchPopup> createState() => _DriverSearchPopupState();
}

class _DriverSearchPopupState extends State<DriverSearchPopup>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _dotsController;
  late AnimationController _successController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _dotsAnimation;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _successFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Loading animations
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Success animation
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _dotsAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _dotsController, curve: Curves.easeInOut),
    );

    _successScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    _successFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOut),
    );

    _startAnimations();
  }

  void _startAnimations() {
    if (widget.state == DriverSearchState.loading) {
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
      _dotsController.repeat();
    } else {
      _pulseController.stop();
      _rotationController.stop();
      _dotsController.stop();
      _successController.forward();
    }
  }

  @override
  void didUpdateWidget(DriverSearchPopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _startAnimations();
      if (widget.state == DriverSearchState.found) {
        widget.onDriverFound?.call();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _dotsController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Widget _buildLoadingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Animated search icon in center
        SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing circles
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.1),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Rotating search circles
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 25,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 25,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withOpacity(0.6),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 25,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withOpacity(0.4),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 25,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Car icon in center
              const Icon(
                Icons.directions_car,
                size: 24,
                color: Colors.blue,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Main text
        const Text(
          'Finding drivers near you',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Animated dots
        AnimatedBuilder(
          animation: _dotsAnimation,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                double delay = index * 0.3;
                double animValue = (_dotsAnimation.value + delay) % 1.0;
                double opacity = animValue < 0.5
                    ? (animValue * 2)
                    : (2 - animValue * 2);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  child: AnimatedOpacity(
                    opacity: opacity.clamp(0.3, 1.0),
                    duration: const Duration(milliseconds: 100),
                    child: const Text(
                      '•',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),

        const SizedBox(height: 24),

        // Cancel button
        if (widget.onCancel != null)
          TextButton(
            onPressed: widget.onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuccessContent() {
    return AnimatedBuilder(
      animation: _successController,
      builder: (context, child) {
        return Transform.scale(
          scale: _successScaleAnimation.value,
          child: FadeTransition(
            opacity: _successFadeAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Driver image/avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: widget.driverImage != null
                      ? ClipOval(
                    child: widget.driverImage!.startsWith('http')
                        ? Image.network(
                      widget.driverImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    )
                        : Image.asset(
                      widget.driverImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar();
                      },
                    ),
                  )
                      : _buildDefaultAvatar(),
                ),

                const SizedBox(height: 20),

                // "or" text
                const Text(
                  'or',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 8),

                // Success message
                const Text(
                  'Your bid has been\naccepted by:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Driver name
                Text(
                  widget.driverName ?? 'Driver',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue,
      ),
      child: const Icon(
        Icons.person,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.transparent,
        child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: widget.state == DriverSearchState.loading
                    ? _buildLoadingContent()
                    : _buildSuccessContent(        ),
              ),
            )
        )
    );
  }
}

// Utility functions for showing popup from PageRouteBuilder context:

class DriverSearchOverlay {
  static OverlayEntry? _overlayEntry;
  static DriverSearchState _currentState = DriverSearchState.loading;
  static String? _driverName;
  static String? _driverImage;

  // Show the popup as an overlay
  static void show(BuildContext context, {VoidCallback? onCancel}) {
    if (_overlayEntry != null) return; // Already showing

    _currentState = DriverSearchState.loading;
    _driverName = null;
    _driverImage = null;

    _overlayEntry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => DriverSearchPopup(
          state: _currentState,
          driverName: _driverName,
          driverImage: _driverImage,
          onCancel: () {
            hide();
            onCancel?.call();
          },
          onDriverFound: () {
            // Optional: Auto-hide after a few seconds
            Future.delayed(const Duration(seconds: 3), () {
              hide();
            });
          },
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // Update the popup when driver is found
  static void updateDriverFound(String name, String? imageUrl) {
    if (_overlayEntry != null) {
      _currentState = DriverSearchState.found;
      _driverName = name;
      _driverImage = imageUrl;
      _overlayEntry!.markNeedsBuild();
    }
  }

  // Hide the popup
  static void hide() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  // Check if popup is currently showing
  static bool get isShowing => _overlayEntry != null;
}