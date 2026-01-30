import 'package:flutter/material.dart';
import 'dart:async';

class RideRequestBottomSheet extends StatefulWidget {
  final String pickup;
  final String drop;
  final String price; // 🔥 Added Price
  final String distance; // 🔥 Added Distance
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RideRequestBottomSheet({
    super.key,
    required this.pickup,
    required this.drop,
    // this.price = "₹120", // Default for testing
    required this.price,
    this.distance = "1.5 km", // Default for testing
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<RideRequestBottomSheet> createState() => _RideRequestBottomSheetState();
}

class _RideRequestBottomSheetState extends State<RideRequestBottomSheet> with SingleTickerProviderStateMixin {
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    // ⏳ 30 Second Timer for Urgency
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..forward();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HEADER: Timer & Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("New Request", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(widget.price, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                        child: Text(widget.distance, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
              // Circular Timer
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 50, height: 50,
                    child: CircularProgressIndicator(
                      value: 0.7, // Static for now, or connect to controller
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.orange,
                      strokeWidth: 4,
                    ),
                  ),
                  const Text("30s", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 2. ROUTE VISUALIZATION (Professional Connector Line)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline Line
                Column(
                  children: [
                    const Icon(Icons.circle, size: 12, color: Colors.green),
                    Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
                    const Icon(Icons.square, size: 12, color: Colors.red),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Addresses
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _addressItem("PICKUP", widget.pickup),
                      const SizedBox(height: 20),
                      _addressItem("DROP-OFF", widget.drop),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 3. ACTION BUTTONS
          Row(
            children: [
              // Reject Button (Smaller)
              Expanded(
                flex: 1,
                child: TextButton(
                  onPressed: widget.onReject,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("DECLINE", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              // Accept Button (Massive & Prominent)
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: widget.onAccept,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Colors.black, // High contrast
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text("ACCEPT RIDE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _addressItem(String label, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(address, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}