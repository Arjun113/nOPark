import 'package:flutter/material.dart';
import 'package:nopark/features/authentications/presentation/widgets/otp_entry_widget.dart';
import 'package:nopark/logic/network/dio_client.dart';

class OTPEntryScreen extends StatefulWidget {
  final String token;
  final String email;

  const OTPEntryScreen({super.key, required this.email, required this.token});

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
        data: {'email': widget.email, 'token': widget.token},
      );
      if (otpVerifyResponse.statusCode == 201 &&
          otpVerifyResponse.data['message'] ==
              'account successfully verified') {
        // TODO: push to next screen
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
                  'Log In',
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
