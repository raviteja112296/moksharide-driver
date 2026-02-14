// ---------------------------------------------------------
// 🚀 RIDE STARTED SHEET (UPDATED CLEAN VERSION)
// ---------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

class RideStartedSheet extends StatefulWidget {
  final String pickupAddress;
  final String dropAddress;
  final GeoPoint? dropLoc;
  final String passengerName;
  final String passengerPhoto;
  final double fareAmount;
  final VoidCallback onCompleteRide;

  const RideStartedSheet({
    super.key,
    required this.pickupAddress,
    required this.dropAddress,
    this.dropLoc,
    required this.passengerName,
    required this.passengerPhoto,
    required this.fareAmount,
    required this.onCompleteRide,
  });

  @override
  State<RideStartedSheet> createState() => _RideStartedSheetState();
}

class _RideStartedSheetState extends State<RideStartedSheet> {
  bool _isCompleted = false;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _flutterTts.setLanguage("en-US");
  }

  void _launchMaps() async {
    if (widget.dropLoc == null) return;

    final Uri url = Uri.parse(
        "google.navigation:q=${widget.dropLoc!.latitude},${widget.dropLoc!.longitude}");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not open navigation");
    }
  }

  Future<bool> _handleCompletion(DismissDirection direction) async {
    setState(() => _isCompleted = true);

    await _flutterTts
        .speak("Ride completed. Collect ${widget.fareAmount.toInt()} rupees.");

    await Future.delayed(const Duration(seconds: 3));
    widget.onCompleteRide();

    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) return _buildSuccessView();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 15),

        // 👤 PASSENGER MINI HEADER + SMALL NAV BUTTON
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(widget.passengerPhoto),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.passengerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),

              // 💰 Fare
              Text(
                "₹${widget.fareAmount.toInt()}",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),

              const SizedBox(width: 10),

              // 🧭 SMALL NAVIGATION BUTTON
              GestureDetector(
                onTap: _launchMaps,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.navigation_rounded,
                    size: 20,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),
        const Divider(),
        const SizedBox(height: 15),

        // 🗺 ROUTE VISUALIZATION
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  const Icon(Icons.circle, size: 12, color: Colors.green),
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey.shade300,
                    ),
                  ),
                  const Icon(Icons.location_on,
                      size: 14, color: Colors.red),
                ],
              ),
              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pickup
                    Text(
                      "PICKUP",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.pickupAddress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),

                    const SizedBox(height: 20),

                    // Drop
                    Text(
                      "DROP",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.dropAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 🟢 SLIDE TO COMPLETE
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Dismissible(
              key: const Key("complete"),
              direction: DismissDirection.startToEnd,
              confirmDismiss: _handleCompletion,
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                color: const Color(0xFF00C853),
                child: const Icon(Icons.check, color: Colors.white),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12, blurRadius: 5)
                        ],
                      ),
                      child: const Icon(Icons.arrow_forward,
                          color: Color(0xFF00C853)),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "SLIDE TO END TRIP",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.black54,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🎉 SUCCESS VIEW
  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Lottie.asset(
          'assets/animations/Success.json',
          width: 140,
          height: 140,
          repeat: false,
        ),
        const Text(
          "TRIP FINISHED",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF00C853),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Collect ₹${widget.fareAmount.toInt()} Cash",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
