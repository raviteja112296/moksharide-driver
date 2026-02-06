import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/home/driver_home_page.dart';

// 🎨 BRAND COLORS (Modify to match your app)
const Color kPrimaryColor = Color(0xFF1E88E5); // Ola/Uber Blue
const Color kDarkColor = Color(0xFF1A1A1A);
const Color kCardColor = Colors.white;

class VehicleSelectionScreen extends StatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  State<VehicleSelectionScreen> createState() => _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState extends State<VehicleSelectionScreen> {
  // 🚗 The selected vehicle type (null initially)
  String? _selectedVehicle;
  bool _isLoading = false;

  // Data for the cards
  final List<Map<String, dynamic>> _vehicles = [
    {'id': 'auto', 'name': 'Auto Rickshaw', 'icon': Icons.local_taxi, 'color': Colors.amber},
    {'id': 'car', 'name': 'Cab / Taxi', 'icon': Icons.directions_car, 'color': Colors.blueAccent},
    {'id': 'bike', 'name': 'Motor Bike', 'icon': Icons.two_wheeler, 'color': Colors.redAccent},
  ];

  // 💾 Logic: Save Selection & Go Home
  Future<void> _handleContinue() async {
    if (_selectedVehicle == null) return;

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // 1. Update Firebase (So users know what vehicle is coming)
      await FirebaseFirestore.instance.collection('drivers').doc(uid).update({
        'vehicle_type': _selectedVehicle,
        'Documents': "not verified", 
      });

      // 2. Save Locally (For app performance)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vehicle_type', _selectedVehicle!);

      // 3. Navigate to Home Page (Replace 'HomePage' with your actual class name)
      if (mounted) {
  Navigator.pushReplacement(
    context, 
    MaterialPageRoute(builder: (context) => const DriverHomePage()), // Ensure this class name matches your file
  );
}
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Clean premium background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👋 Header
              const SizedBox(height: 20),
              Text(
                "Welcome Partner,",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Choose Your Vehicle",
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kDarkColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Select the vehicle you are driving today to start receiving rides.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),

              const SizedBox(height: 40),

              // 🚗 The Animated Cards Grid
              Expanded(
                child: ListView.separated(
                  itemCount: _vehicles.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final vehicle = _vehicles[index];
                    final isSelected = _selectedVehicle == vehicle['id'];

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedVehicle = vehicle['id']);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: 100, // Premium Card Height
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: isSelected ? kPrimaryColor.withOpacity(0.1) : kCardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? kPrimaryColor : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            // Icon Container
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: vehicle['color'].withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                vehicle['icon'],
                                color: vehicle['color'],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Text Info
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    vehicle['name'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: kDarkColor,
                                    ),
                                  ),
                                  if (isSelected)
                                    Text(
                                      "Selected",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: kPrimaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Checkmark
                            if (isSelected)
                              const Icon(Icons.check_circle, color: kPrimaryColor, size: 24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 🚀 Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedVehicle == null || _isLoading ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _selectedVehicle == null ? 0 : 5,
                    shadowColor: kPrimaryColor.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "CONTINUE TO DASHBOARD",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
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