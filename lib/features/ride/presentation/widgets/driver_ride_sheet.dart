import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:moksharide_driver/features/ride/presentation/widgets/ride_started_sheet.dart';
import 'package:moksharide_driver/features/ride/presentation/widgets/waiting_otp_sheet.dart';

class DriverRideSheet extends StatelessWidget {
  final String rideStatus; // accepted | started
  final bool otpVerified;
  final String rideId;
  final String rideOtp;
  
  // Route Data
  final String pickupAddress; // 🆕 Added for Route Line
  final String dropAddress; 
  final GeoPoint? dropLoc;

  // Passenger Data (Pass these from parent or use defaults)
  final String passengerName;
  final String passengerPhoto;
  final double fareAmount;

  final VoidCallback onVerifyOtp;
  final VoidCallback onCompleteRide;

  const DriverRideSheet({
    super.key,
    required this.rideStatus,
    required this.otpVerified,
    required this.rideId,
    required this.rideOtp,
    required this.pickupAddress,
    required this.dropAddress,
    this.dropLoc,
    this.passengerName = "Rahul Kumar", // Default for demo
    this.passengerPhoto = "https://i.pravatar.cc/150?img=11",
    required this.fareAmount,
    required this.onVerifyOtp,
    required this.onCompleteRide,
  });

  @override
  Widget build(BuildContext context) {
    // 1. WAITING FOR PASSENGER
    if (rideStatus == 'accepted' && !otpVerified) {
      return _FixedSheet(
        child: WaitingOtpSheet(
          rideId: rideId,
          storedOtp: rideOtp,
          passengerName: passengerName,
          passengerPhoto: passengerPhoto,
          fareAmount: fareAmount,
        ),
      );
    }

    // 2. RIDE IN PROGRESS
    if (rideStatus == 'started' || otpVerified) {
      return _FixedSheet(
        child: RideStartedSheet(
          pickupAddress: pickupAddress,
          dropAddress: dropAddress,
          dropLoc: dropLoc,
          passengerName: passengerName,
          passengerPhoto: passengerPhoto,
          fareAmount: fareAmount,
          onCompleteRide: onCompleteRide,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}




// ---------------------------------------------------------
// 📦 FIXED SHEET (Replaces DraggableScrollableSheet)
// ---------------------------------------------------------
class _FixedSheet extends StatelessWidget {
  final Widget child;
  const _FixedSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), // Bottom padding for safe area
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 25, spreadRadius: 2)],
        ),
        child: SafeArea(
          top: false, // Don't add padding for notch
          child: child,
        ),
      ),
    );
  }
}