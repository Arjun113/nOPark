import 'package:flutter/material.dart';

class DriverInfoCard extends StatelessWidget {
  final String driverName;
  final String profileImageUrl;
  final VoidCallback? onCancelRide;
  final VoidCallback? onSendMessage;
  final VoidCallback? onCall;

  const DriverInfoCard({
    Key? key,
    required this.driverName,
    required this.profileImageUrl,
    this.onCancelRide,
    this.onSendMessage,
    this.onCall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Driver info section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile picture
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF6B9EFF), // Light blue background
                        ),
                        child: ClipOval(
                          child: Image.network(
                            profileImageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to avatar icon if image fails to load
                              return const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Driver name
                      Text(
                        driverName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          fontFamily: "GoogleSans"
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Driver role
                      const Text(
                        'Student',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                          fontFamily: "GoogleSans"
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action buttons row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Send message button
                          _ActionButton(
                            icon: Icons.message_outlined,
                            label: 'Send a message',
                            onTap: onSendMessage,
                          ),

                          // Call button
                          _ActionButton(
                            icon: Icons.phone_outlined,
                            label: 'Call',
                            onTap: onCall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Cancel ride button
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: ElevatedButton(
                    onPressed: onCancelRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade300, // Light pink/coral
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel Ride',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent,
                        fontFamily: "GoogleSans"
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
                fontFamily: "GoogleSans"
              ),
            ),
          ],
        ),
      ),
    );
  }
}
