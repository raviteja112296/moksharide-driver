import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DriverRideSheet extends StatelessWidget {
  final String rideStatus; // accepted | started
  final bool otpVerified;

  final String rideId;
  final String rideOtp;

  final VoidCallback onVerifyOtp;
  final VoidCallback onCompleteRide;

  const DriverRideSheet({
    super.key,
    required this.rideStatus,
    required this.otpVerified,
    required this.rideId,
    required this.rideOtp,
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
        onCompleteRide: onCompleteRide,
      );
    }

    return const SizedBox.shrink();
  }
}
class WaitingOtpSheet extends StatefulWidget {
  final String rideId;
  final String storedOtp;

  const WaitingOtpSheet({
    super.key,
    required this.rideId,
    required this.storedOtp,
  });

  @override
  State<WaitingOtpSheet> createState() => _WaitingOtpSheetState();
}

class _WaitingOtpSheetState extends State<WaitingOtpSheet> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  bool _loading = false;

  String get _otp => _controllers.map((e) => e.text).join();
  bool get _complete => _controllers.every((e) => e.text.isNotEmpty);

  Future<void> _verify() async {
    if (!_complete) return;

    setState(() => _loading = true);

    if (_otp == widget.storedOtp) {
      await FirebaseFirestore.instance
          .collection('ride_requests')
          .doc(widget.rideId)
          .update({
        'status': 'started',
        'startedAt': FieldValue.serverTimestamp(),
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid OTP"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return BaseSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SheetHandle(),

          const SizedBox(height: 12),

          const Icon(Icons.lock_outline,
              size: 36, color: Colors.orange),

          const SizedBox(height: 8),

          const Text(
            "Enter Ride OTP",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Ask the customer for the OTP to start ride",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _controllers[i],
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
                  ),
                  onChanged: (_) {
                    if (i < 3) FocusScope.of(context).nextFocus();
                  },
                ),
              );
            }),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "START RIDE",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
class RideStartedSheet extends StatelessWidget {
  final VoidCallback onCompleteRide;

  const RideStartedSheet({super.key, required this.onCompleteRide});

  @override
  Widget build(BuildContext context) {
    return BaseSheet(
      child: Column(
        children: [
          _SheetHandle(),

          const SizedBox(height: 12),

          const Icon(Icons.navigation,
              size: 36, color: Colors.green),

          const SizedBox(height: 8),

          const Text(
            "Ride in Progress",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Navigate to destination safely",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 24),

          GestureDetector(
            onVerticalDragEnd: (_) => onCompleteRide(),
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Text(
                "⬆ SWIPE UP TO COMPLETE",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class BaseSheet extends StatelessWidget {
  final Widget child;

  const BaseSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.32,
      minChildSize: 0.28,
      maxChildSize: 0.38,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: ListView(
            controller: controller,
            children: [child],
          ),
        );
      },
    );
  }
}
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
