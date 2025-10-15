import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:nopark/features/authentications/datasources/local_datastorer.dart';
import 'package:nopark/features/authentications/presentation/screens/otp_entry_screen.dart';
import 'package:nopark/features/feeds/presentation/screens/driver_home.dart';
import 'package:nopark/features/feeds/presentation/screens/passenger_home.dart';
import 'package:nopark/logic/network/dio_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await DioClient().client.post(
        '/accounts/login',
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        },
      );
      final token = response.data['token'];
      CredentialStorage.setLoginToken(token);
      if (response.data.type == "driver" && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DriverHomePage()),
        );
      } else if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PassengerHomePage()),
        );
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.data != null &&
            e.response!.data.toString().contains("not verified")) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        OTPEntryScreen(email: _emailController.text.trim()),
              ),
            );
          }
          return;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to login')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  OutlineInputBorder _customBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: color, width: 1.5),
    );
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
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.black87),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  enabledBorder: _customBorder(const Color(0xFFFFB74D)),
                  focusedBorder: _customBorder(const Color(0xFFFFB74D)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.black87),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  enabledBorder: _customBorder(const Color(0xFFFFB74D)),
                  focusedBorder: _customBorder(const Color(0xFFFFB74D)),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB74D), // orange
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _isLoading ? null : _login,
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
              const SizedBox(height: 24),
              const Text(
                "New User?",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1), // blue
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text(
                  'Register',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
