import 'package:flutter/material.dart';
import 'package:nopark/features/authentications/presentation/widgets/otp_entry_widget.dart';
import 'package:nopark/features/signup/interface/widgets/login_screen.dart';
import 'package:nopark/logic/network/dio_client.dart';

class OTPEntryScreen extends StatefulWidget {
  final String email;

  const OTPEntryScreen({super.key, required this.email});

  @override
  State<StatefulWidget> createState() {
    return OTPEntryScreenState();
  }
}

class OTPEntryScreenState extends State<OTPEntryScreen> {
  late TextEditingController otpController;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    otpController = TextEditingController();
  }

  Future<void> verify() async {
    if (otpController.text.length == 6) {
      final otpVerifyResponse = await DioClient().client.post(
        '/accounts/verify-email',
        data: {'email': widget.email, 'token': otpController.text},
      );
      if (otpVerifyResponse.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/main_logo.png', height: 100),
              const SizedBox(height: 40),
              OTPEntry(otpLength: 6, controller: otpController),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB74D), // orange
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _isLoading ? null : verify,
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Verify',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
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
