import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:url_launcher/url_launcher.dart'; // Run: flutter pub add url_launcher

class DriverRideSheet extends StatelessWidget {
  final String rideStatus; // accepted | started
  final bool otpVerified;
  final String rideId;
  final String rideOtp;
  
  // Pass these for the "Started" UI
  final String dropAddress; 
  final GeoPoint? dropLoc;

  final VoidCallback onVerifyOtp;
  final VoidCallback onCompleteRide;

  const DriverRideSheet({
    super.key,
    required this.rideStatus,
    required this.otpVerified,
    required this.rideId,
    required this.rideOtp,
    required this.dropAddress, // New
    this.dropLoc,              // New
    required this.onVerifyOtp,
    required this.onCompleteRide,
  });

  @override
  Widget build(BuildContext context) {
    if (rideStatus == 'accepted' && !otpVerified) {
      return WaitingOtpSheet(
        rideId: rideId,
        storedOtp: rideOtp,
      );
    }

    if (rideStatus == 'started' || otpVerified) {
      return RideStartedSheet(
        dropAddress: dropAddress,
        dropLoc: dropLoc,
        onCompleteRide: onCompleteRide,
      );
    }

    return const SizedBox.shrink();
  }
}

// ---------------------------------------------------------
// 🔒 OTP SHEET (Improved with Pinput)
// ---------------------------------------------------------
class WaitingOtpSheet extends StatefulWidget {
  final String rideId;
  final String storedOtp;

  const WaitingOtpSheet({super.key, required this.rideId, required this.storedOtp});

  @override
  State<WaitingOtpSheet> createState() => _WaitingOtpSheetState();
}

class _WaitingOtpSheetState extends State<WaitingOtpSheet> {
  final TextEditingController _otpController = TextEditingController();
  bool _loading = false;

  Future<void> _verify(String pin) async {
    if (pin.length != 4) return;
    setState(() => _loading = true);

    if (pin == widget.storedOtp) {
      // ✅ Using Firestore logic here (Or call your Repository)
      await FirebaseFirestore.instance
          .collection('ride_requests')
          .doc(widget.rideId)
          .update({
        'status': 'started',
        'startedAt': FieldValue.serverTimestamp(),
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wrong OTP! Ask passenger again."), backgroundColor: Colors.red),
      );
      _otpController.clear();
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return BaseSheet(
      child: Column(
        children: [
          _SheetHandle(),
          const SizedBox(height: 10),
          const Text("Verify Passenger", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Ask for the 4-digit PIN", style: TextStyle(color: Colors.grey)),
          
          const SizedBox(height: 20),

          // ✨ Pro Pinput Integration
          Pinput(
            length: 4,
            controller: _otpController,
            autofocus: true, // Key for speed!
            onCompleted: _verify, // Verify immediately when filled
            defaultPinTheme: PinTheme(
              width: 55, height: 55,
              textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            focusedPinTheme: PinTheme(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 25),
          if (_loading) const CircularProgressIndicator()
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 🚀 STARTED SHEET (With Slide-to-End & Navigation)
// ---------------------------------------------------------
class RideStartedSheet extends StatelessWidget {
  final String dropAddress;
  final GeoPoint? dropLoc;
  final VoidCallback onCompleteRide;

  const RideStartedSheet({
    super.key,
    required this.dropAddress,
    required this.onCompleteRide,
    this.dropLoc,
  });

  void _launchMaps() async {
    if (dropLoc == null) return;
    final url = Uri.parse("google.navigation:q=${dropLoc!.latitude},${dropLoc!.longitude}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _SheetHandle()),
          const SizedBox(height: 15),

          // 1. Destination Info (CRITICAL)
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Drop Location", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(dropAddress, 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 2. Navigation Button
              IconButton.filled(
                onPressed: _launchMaps,
                icon: const Icon(Icons.navigation),
                style: IconButton.styleFrom(backgroundColor: Colors.blue),
              )
            ],
          ),

          const Spacer(),

          // 3. Slide to Complete (Safer than vertical swipe)
          // Using a Dismissible as a simple "Slide" trick
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(30),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Dismissible(
                key: const Key("complete_ride"),
                direction: DismissDirection.startToEnd,
                confirmDismiss: (direction) async {
                  onCompleteRide();
                  return false; // Don't remove widget, just run callback
                },
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  color: Colors.green,
                  child: const Icon(Icons.check_circle, color: Colors.white),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text("SLIDE TO COMPLETE", 
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 📦 BASE SHEET & HELPERS
// ---------------------------------------------------------
class BaseSheet extends StatelessWidget {
  final Widget child;
  const BaseSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.35,
      minChildSize: 0.35,
      maxChildSize: 0.45,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 5)],
          ),
          child: child, // Removed ListView to allow Spacer() to work
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}