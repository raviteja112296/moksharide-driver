// import 'package:flutter/material.dart';
// import 'package:pinput/pinput.dart';

// class RideControlPanel extends StatefulWidget {
//   final String rideId;
//   final String status; // 'accepted', 'arrived', 'started'
//   final Function(String) onStatusUpdate;

//   const RideControlPanel({
//     super.key,
//     required this.rideId,
//     required this.status,
//     required this.onStatusUpdate,
//   });

//   @override
//   State<RideControlPanel> createState() => _RideControlPanelState();
// }

// class _RideControlPanelState extends State<RideControlPanel> {
//   final TextEditingController _otpController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//         boxShadow: [
//           BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           // 1. Drag Handle
//           Center(
//             child: Container(
//               width: 40, height: 4,
//               margin: const EdgeInsets.only(bottom: 20),
//               decoration: BoxDecoration(
//                 color: Colors.grey[300], 
//                 borderRadius: BorderRadius.circular(10)
//               ),
//             ),
//           ),

//           // 2. Dynamic UI based on Status
//           if (widget.status == 'accepted') _buildArrivedView(),
//           if (widget.status == 'arrived') _buildOtpView(),
//           if (widget.status == 'started' || widget.status == 'ongoing') _buildEndRideView(),
//         ],
//       ),
//     );
//   }

//   // 🚖 PHASE 1: DRIVING TO PICKUP
//   Widget _buildArrivedView() {
//     return Column(
//       children: [
//         const Text(
//           "Picking up Passenger",
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         const Text("Drive to the pickup location shown on map.", style: TextStyle(color: Colors.grey)),
//         const SizedBox(height: 20),
        
//         // Navigation Button (Optional Dummy)
//         OutlinedButton.icon(
//           onPressed: () {}, // Open Google Maps Logic here if you want
//           icon: const Icon(Icons.navigation),
//           label: const Text("NAVIGATE"),
//           style: OutlinedButton.styleFrom(
//             padding: const EdgeInsets.symmetric(vertical: 14),
//             side: const BorderSide(color: Colors.blue),
//           ),
//         ),
//         const SizedBox(height: 12),

//         // MAIN ACTION
//         _buildActionButton(
//           label: "I HAVE ARRIVED",
//           color: Colors.orange,
//           icon: Icons.location_on,
//           onTap: () => widget.onStatusUpdate('arrived'),
//         ),
//       ],
//     );
//   }

//   // 🔢 PHASE 2: WAITING FOR OTP
//   Widget _buildOtpView() {
//     return Column(
//       children: [
//         const Text(
//           "Verify OTP",
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         const Text("Ask passenger for the 4-digit code", style: TextStyle(color: Colors.grey)),
//         const SizedBox(height: 20),

//         // OTP INPUT
//         Pinput(
//           length: 4,
//           controller: _otpController,
//           defaultPinTheme: PinTheme(
//             width: 56,
//             height: 56,
//             textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey.shade300),
//               borderRadius: BorderRadius.circular(12),
//               color: Colors.grey.shade50,
//             ),
//           ),
//           onCompleted: (pin) {
//             // Automatically trigger start when 4 digits entered
//             widget.onStatusUpdate(pin);
//             _otpController.clear();
//           },
//         ),
//         const SizedBox(height: 20),
//         const Text("Ride starts automatically after verification", style: TextStyle(fontSize: 12, color: Colors.blue)),
//       ],
//     );
//   }

//   // 🏁 PHASE 3: RIDE IN PROGRESS
//   Widget _buildEndRideView() {
//     return Column(
//       children: [
//         const Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.directions_car, color: Colors.green),
//             SizedBox(width: 8),
//             Text("Ride in Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
//           ],
//         ),
//         const SizedBox(height: 8),
//         const Text("Head towards the drop location.", style: TextStyle(color: Colors.grey)),
//         const SizedBox(height: 20),

//         _buildActionButton(
//           label: "COMPLETE RIDE",
//           color: Colors.red,
//           icon: Icons.flag,
//           onTap: () => widget.onStatusUpdate('completed'),
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton({required String label, required Color color, required IconData icon, required VoidCallback onTap}) {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton.icon(
//         onPressed: onTap,
//         icon: Icon(icon, color: Colors.white),
//         label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: color,
//           padding: const EdgeInsets.symmetric(vertical: 16),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           elevation: 4,
//         ),
//       ),
//     );
//   }
// }