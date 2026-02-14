// ---------------------------------------------------------
// 🟢 WAITING & OTP SHEET (UPDATED CLEAN VERSION)
// ---------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:url_launcher/url_launcher.dart';

class WaitingOtpSheet extends StatefulWidget {
  final String rideId;
  final String storedOtp;
  final String passengerName;
  final String passengerPhoto;
  final double fareAmount;

  const WaitingOtpSheet({
    super.key,
    required this.rideId,
    required this.storedOtp,
    required this.passengerName,
    required this.passengerPhoto,
    required this.fareAmount,
  });

  @override
  State<WaitingOtpSheet> createState() => _WaitingOtpSheetState();
}

class _WaitingOtpSheetState extends State<WaitingOtpSheet> {
  final TextEditingController _otpController = TextEditingController();
  bool _loading = false;

  final String _passengerPhone = "+919603832514";

  Future<void> _makeCall() async {
    final Uri uri = Uri.parse("tel:$_passengerPhone");
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not open dialer");
    }
  }

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
        const SnackBar(
          content: Text("Wrong OTP!"),
          backgroundColor: Colors.red,
        ),
      );
      _otpController.clear();
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 15),

        // 👤 PASSENGER CARD (UPDATED WITH PHONE ICON)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: NetworkImage(widget.passengerPhoto),
                backgroundColor: Colors.grey.shade200,
              ),

              const SizedBox(width: 12),

              // Name & Trip Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.passengerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Cash Trip",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // 💰 Fare
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "₹${widget.fareAmount.toInt()}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF00C853),
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // 📞 CALL ICON BUTTON
              GestureDetector(
                onTap: _makeCall,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2962FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone,
                    color: Color(0xFF2962FF),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        // 🔢 OTP TITLE
        const Text(
          "ENTER START CODE",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1,
          ),
        ),

        const SizedBox(height: 12),

        // 🔢 OTP INPUT
        Pinput(
          length: 4,
          controller: _otpController,
          onCompleted: _verify,
          defaultPinTheme: PinTheme(
            width: 55,
            height: 55,
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          focusedPinTheme: PinTheme(
            width: 60,
            height: 60,
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF00BFA5),
                width: 2,
              ),
            ),
          ),
        ),

        if (_loading)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(
              color: Color(0xFF00BFA5),
            ),
          ),

        const SizedBox(height: 15),
      ],
    );
  }
}
