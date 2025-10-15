import 'package:flutter/material.dart';
import 'package:nopark/logic/network/dio_client.dart';

class VehicleInfoScreen extends StatefulWidget {
  const VehicleInfoScreen({super.key});

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  final _modelController = TextEditingController();
  final _modelYearController = TextEditingController();
  final _colourController = TextEditingController();
  final _licensePlateController = TextEditingController();

  bool _isLoading = false;

  OutlineInputBorder _customBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }

  Future<void> _saveVehicleInfo() async {
    final model = _modelController.text.trim();
    final modelYear = _modelYearController.text.trim();
    final colour = _colourController.text.trim();
    final licensePlate = _licensePlateController.text.trim().toUpperCase();

    if (model.isEmpty ||
        modelYear.isEmpty ||
        colour.isEmpty ||
        licensePlate.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    final year = int.tryParse(modelYear);
    if (year == null || year < 1900 || year > DateTime.now().year + 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid model year')));
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await DioClient().client.post(
        '/accounts/vehicle',
        data: {
          'model': model,
          'model_year': year,
          'colour': colour,
          'license_plate': licensePlate,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle added successfully!')),
        );
        Navigator.pop(context);
      } else if (response.statusCode == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This license plate is already registered'),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${response.data}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to the server: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _modelYearController.dispose();
    _colourController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        title: const Text(
          'Add Vehicle Info',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Image.asset('assets/vehicle_icon.png', height: 100),
              const SizedBox(height: 30),

              // Model
              TextField(
                controller: _modelController,
                decoration: InputDecoration(
                  labelText: 'Model',
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

              // Model Year
              TextField(
                controller: _modelYearController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Model Year',
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

              // Colour
              TextField(
                controller: _colourController,
                decoration: InputDecoration(
                  labelText: 'Colour',
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

              // License Plate
              TextField(
                controller: _licensePlateController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'License Plate',
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

              // Save Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: _isLoading ? null : _saveVehicleInfo,
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'Save Vehicle Info',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
