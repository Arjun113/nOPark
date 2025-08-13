import 'package:flutter/material.dart';

class DisclaimerWidget extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const DisclaimerWidget({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<DisclaimerWidget> createState() => _DisclaimerWidgetState();
}

class _DisclaimerWidgetState extends State<DisclaimerWidget> {
  bool _agreeChecked = false;
  bool _loading = false;

  final String _disclaimerText =
      'Important: Please read this legal disclaimer carefully before using the app.\n\n'
      'By tapping "I Accept" you acknowledge that you have read and understood the terms, and you agree to comply with all applicable laws and the app\'s policies.\n\n'
      'This app is provided "as-is" without warranties of any kind. The creators are not liable for any damages or losses resulting from use of the app.\n\n'
      'For the full Terms of Service and Privacy Policy visit our website or contact support@company.com.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal Disclaimer'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Before you continue',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text(_disclaimerText),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Checkbox(
                            value: _agreeChecked,
                            onChanged:
                                (v) =>
                                    setState(() => _agreeChecked = v ?? false),
                          ),
                          const Expanded(
                            child: Text(
                              'I have read and agree to the Terms of Service and Privacy Policy.',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const TermsScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Read full Terms of Service and Privacy Policy',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onDecline,
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _agreeChecked && !_loading
                              ? () {
                                setState(() => _loading = true);
                                widget.onAccept();
                              }
                              : null,
                      child:
                          _loading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('I Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Privacy')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'Full Terms of Service and Privacy Policy go here.\n\n'
            'This is a placeholder; replace with your organisation\'s real terms.',
          ),
        ),
      ),
    );
  }
}

// use this code  in the main activity run it on the emulator
// import 'package:flutter/material.dart';
// import 'disclaimer_widget.dart'; // we’ll create this next

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Disclaimer Demo',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: DisclaimerWidget(
//         onAccept: () {

//           print("User accepted");
//         },
//         onDecline: () {

//           print("User declined");
//         },
//       ),
//     );
//   }
// }
