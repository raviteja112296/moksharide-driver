import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_tts/flutter_tts.dart'; // 📦 NEW: Import TTS

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
    required this.dropAddress,
    this.dropLoc,
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
// 🔒 OTP SHEET
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

          Pinput(
            length: 4,
            controller: _otpController,
            autofocus: true,
            onCompleted: _verify,
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
// 🚀 STARTED SHEET (With Animation & Audio)
// ---------------------------------------------------------
class RideStartedSheet extends StatefulWidget {
  final String dropAddress;
  final GeoPoint? dropLoc;
  final VoidCallback onCompleteRide;

  const RideStartedSheet({
    super.key,
    required this.dropAddress,
    required this.onCompleteRide,
    this.dropLoc,
  });

  @override
  State<RideStartedSheet> createState() => _RideStartedSheetState();
}

class _RideStartedSheetState extends State<RideStartedSheet> {
  bool _isCompleted = false; 
  final FlutterTts _flutterTts = FlutterTts(); // 🔊 1. TTS Instance

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  // 🔊 2. Configure Voice Settings
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // 0.5 is clear and normal speed
    await _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    _flutterTts.stop(); // Stop audio if they leave the screen
    super.dispose();
  }

  void _launchMaps() async {
    if (widget.dropLoc == null) return;
    final url = Uri.parse("google.navigation:q=${widget.dropLoc!.latitude},${widget.dropLoc!.longitude}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<bool> _handleCompletion(DismissDirection direction) async {
    // 1. Show Animation
    setState(() {
      _isCompleted = true; 
    });

    // 2. 🗣️ Speak Message
    await _flutterTts.speak("Thank you for completing safely.");

    // 3. Wait for Animation + Audio (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    // 4. Actually Complete the Ride
    widget.onCompleteRide();
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BaseSheet(
      // ✨ Use Stack to overlay animation on top of UI
      child: Stack(
        children: [
          // --------------------------
          // 1. NORMAL UI (Hidden when completed)
          // --------------------------
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isCompleted ? 0.0 : 1.0, // Fade out when completed
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _SheetHandle()),
                const SizedBox(height: 15),

                // Destination
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Drop Location", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(widget.dropAddress, 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      onPressed: _launchMaps,
                      icon: const Icon(Icons.navigation),
                      style: IconButton.styleFrom(backgroundColor: Colors.blue),
                    )
                  ],
                ),

                const Spacer(),

                // Slide to Complete
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
                      confirmDismiss: _handleCompletion, // 👈 TTS Logic Inside Here
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
          ),

          // --------------------------
          // 2. SUCCESS ANIMATION (Visible only when completed)
          // --------------------------
          if (_isCompleted)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🎉 Confetti & Checkmark Animation
                  Lottie.asset(
                    'assets/animations/Success.json',
                    width: 200,
                    height: 200,
                    repeat: false,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "RIDE COMPLETED!",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
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
          child: child,
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