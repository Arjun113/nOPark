import 'package:flutter/material.dart';
import 'package:nopark/features/profiles/presentation/widgets/address_add_input.dart';
import 'package:nopark/logic/network/dio_client.dart';

import '../../../trip/entities/user.dart';

enum ProfileSheetState { collapsed, expanded }

class ProfileBottomSheet extends StatefulWidget {
  final User user;
  final String userRole;
  final TextEditingController emailController;
  final String? profileImageUrl;
  final int ridesCount;
  final List<Map<String, dynamic>> addresses;
  final VoidCallback? onLogOut;
  final VoidCallback? onBecomeDriver;
  final Widget? savedAddressesWidget;

  const ProfileBottomSheet({
    super.key,
    required this.user,
    required this.userRole,
    required this.emailController,
    required this.addresses,
    this.profileImageUrl,
    this.ridesCount = 0,
    this.onLogOut,
    this.onBecomeDriver,
    this.savedAddressesWidget,
  });

  @override
  State<ProfileBottomSheet> createState() => _ProfileBottomSheetState();
}

class _ProfileBottomSheetState extends State<ProfileBottomSheet>
    with SingleTickerProviderStateMixin {
  ProfileSheetState _currentState = ProfileSheetState.collapsed;
  late final AnimationController _animationController;
  late final Animation<double> _heightAnimation;
  bool _isDarkMode = false;
  bool _isEmailEditing = false;

  @override
  void initState() {
    super.initState();
    debugPrint("onLogOut is ${widget.onLogOut == null ? 'null' : 'set!'}");
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _heightAnimation = Tween<double>(
      begin: 0.5,
      end: 0.9,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  void _toggleSheet() {
    setState(() {
      if (_currentState == ProfileSheetState.collapsed) {
        _currentState = ProfileSheetState.expanded;
        _animationController.forward();
      } else {
        _currentState = ProfileSheetState.collapsed;
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildProfileImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget.profileImageUrl != null
          ? ClipOval(
        child: Image.network(
          widget.profileImageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      )
          : _buildDefaultAvatar(),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Icon(Icons.person, size: 40, color: Colors.white),
    );
  }

  Widget _buildCollapsedContent() {
    return Column(
      children: [
        _buildProfileImage(),
        const SizedBox(height: 16),
        Text(
          '${widget.user.firstName ?? ""} ${widget.user.lastName ?? ""}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.userRole,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '${widget.ridesCount}',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Rides Taken',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: ElevatedButton(
            onPressed: _toggleSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Update Profile',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: ElevatedButton(
            onPressed: widget.onLogOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[100],
              foregroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildProfileImage(),
        Text(
          '${widget.user.firstName ?? ""} ${widget.user.lastName ?? ""}',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.userRole,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),

        // Contact info
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildContactRow(
                Icons.email,
                widget.emailController,
                _isEmailEditing,
                    () {
                  setState(() {
                    _isEmailEditing = !_isEmailEditing;
                  });
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        if (widget.savedAddressesWidget != null)
          ...[
            widget.savedAddressesWidget!,
            const SizedBox(height: 24),
          ]
        else
          ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saved Addresses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: widget.addresses.map((address) {
                          final name = address['name']?.toString() ?? 'Unnamed';
                          final line1 = address['line1']?.toString() ?? '';
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  line1,
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: GestureDetector(
                      onTap: () async {
                        final newAddress = await showAddressPopup(context);
                        if (newAddress == null) return;

                        try {
                          final response = await DioClient().client.post(
                            '/accounts/addresses',
                            data: {
                              'address_name':
                              newAddress.addressNameController.text,
                              'address_line':
                              (newAddress.addressLine1Controller.text) +
                                  (newAddress.addressLine2Controller.text),
                            },
                          );

                          if (response.statusCode == 204) {
                            // Always update data, even if widget unmounted
                            widget.addresses.add({
                              'name':
                              newAddress.addressNameController.text.trim(),
                              'line1':
                              newAddress.addressLine1Controller.text.trim(),
                              'line2':
                              newAddress.addressLine2Controller.text.trim(),
                            });

                            debugPrint(
                                'Address list updated: ${widget.addresses.length}');

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Address Added!")),
                              );
                              setState(() {});
                            }
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Failed to add address. Please try again."),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    "Error communicating with the server: $e"),
                              ),
                            );
                          }
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

        // Dark mode toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dark Mode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Switch(
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() => _isDarkMode = value);
                },
                activeThumbColor: Colors.orange,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onLogOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[100],
              foregroundColor: Colors.red[700],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Made with ❤️ in Australia',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContactRow(
      IconData icon,
      TextEditingController controller,
      bool isEditing,
      VoidCallback onEditToggle,
      ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: isEditing
              ? TextField(
            controller: controller,
            style:
            const TextStyle(fontSize: 16, color: Colors.black87),
            decoration: InputDecoration(
              border: UnderlineInputBorder(
                borderSide:
                BorderSide(color: Colors.blue[300]!),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                BorderSide(color: Colors.blue[500]!),
              ),
              isDense: true,
              contentPadding:
              const EdgeInsets.symmetric(vertical: 4),
            ),
            autofocus: true,
            onEditingComplete: () {
              setState(() {
                _isEmailEditing = false;
              });
            },
          )
              : Text(
            controller.text,
            style: const TextStyle(
                fontSize: 16, color: Colors.black87),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onEditToggle,
          child: Icon(
            isEditing ? Icons.check : Icons.edit,
            size: 16,
            color: isEditing ? Colors.blue[500] : Colors.grey[400],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _heightAnimation,
      builder: (context, child) {
        return Container(
          height: MediaQuery.of(context).size.height *
              _heightAnimation.value,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (_currentState ==
                  ProfileSheetState.expanded)
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _toggleSheet,
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24),
                  child: _currentState ==
                      ProfileSheetState.collapsed
                      ? _buildCollapsedContent()
                      : _buildExpandedContent(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
