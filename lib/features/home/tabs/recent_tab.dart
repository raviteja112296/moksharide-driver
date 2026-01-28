// // lib/features/home/tabs/recent_tab.dart
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';


// class RecentTab extends StatelessWidget {
//   const RecentTab({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;
    
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             // 🔥 Filter Header
//             Container(
//               padding: EdgeInsets.all(20),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.search, color: Colors.grey[600]),
//                           SizedBox(width: 12),
//                           Text('Recent rides', style: TextStyle(color: Colors.grey[600])),
//                         ],
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: 12),
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                     decoration: BoxDecoration(
//                       color: Colors.blueAccent,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       DateFormat('MMM yyyy').format(DateTime.now()),
//                       style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
            
//             // 🔥 Rides List
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream: user != null 
//                     ? FirebaseFirestore.instance
//                         .collection('rides')
//                         .where('driverId', isEqualTo: user.uid)
//                         .orderBy('createdAt', descending: true)
//                         .limit(50)
//                         .snapshots()
//                     : Stream.empty(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return Center(child: CircularProgressIndicator());
//                   }
                  
//                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                     return Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.history, size: 80, color: Colors.grey[400]),
//                           SizedBox(height: 16),
//                           Text(
//                             'No recent rides',
//                             style: TextStyle(fontSize: 20, color: Colors.grey[600]),
//                           ),
//                           Text(
//                             'Completed rides will appear here',
//                             style: TextStyle(color: Colors.grey[500]),
//                           ),
//                         ],
//                       ),
//                     );
//                   }
                  
//                   return ListView.builder(
//                     padding: EdgeInsets.symmetric(horizontal: 20),
//                     itemCount: snapshot.data!.docs.length,
//                     itemBuilder: (context, index) {
//                       final ride = snapshot.data!.docs[index];
//                       final data = ride.data() as Map<String, dynamic>;
                      
//                       return _RideCard(ride: data, docId: ride.id);
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _RideCard extends StatelessWidget {
//   final Map<String, dynamic> ride;
//   final String docId;

//   const _RideCard({required this.ride, required this.docId});

//   @override
//   Widget build(BuildContext context) {
//     final status = ride['status']?.toString() ?? 'unknown';
//     final createdAt = (ride['createdAt'] as Timestamp?)?.toDate();
//     final amount = ride['driverAmount']?.toString() ?? '₹0';
    
//     return Container(
//       margin: EdgeInsets.only(bottom: 16),
//       child: Card(
//         elevation: 4,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Padding(
//           padding: EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // 🔥 Ride Header
//               Row(
//                 children: [
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: _getStatusColor(status),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       _getStatusText(status),
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                   Spacer(),
//                   Text(
//                     amount,
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 16),
              
//               // 🔥 Route Info
//               Row(
//                 children: [
//                   Icon(Icons.my_location, color: Colors.grey[600], size: 20),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       ride['pickupAddress']?.toString() ?? 'Pickup location',
//                       style: TextStyle(fontWeight: FontWeight.w500),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 8),
//               Row(
//                 children: [
//                   Icon(Icons.location_on, color: Colors.green[600], size: 20),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       ride['destinationAddress']?.toString() ?? 'Destination',
//                       style: TextStyle(fontWeight: FontWeight.w500),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 16),
              
//               // 🔥 Bottom Details
//               Divider(),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     createdAt != null 
//                         ? DateFormat('MMM dd, HH:mm').format(createdAt) 
//                         : 'Unknown time',
//                     style: TextStyle(color: Colors.grey[600]),
//                   ),
//                   Text(
//                     '${ride['distance']?.toStringAsFixed(1) ?? '0'} km',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blueAccent,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getStatusColor(String status) {
//     switch (status) {
//       case 'completed': return Colors.green;
//       case 'cancelled': return Colors.red;
//       case 'confirmed': return Colors.blue;
//       default: return Colors.orange;
//     }
//   }

//   String _getStatusText(String status) {
//     switch (status) {
//       case 'completed': return 'Completed';
//       case 'cancelled': return 'Cancelled';
//       case 'confirmed': return 'Confirmed';
//       case 'pending': return 'Pending';
//       default: return status.toUpperCase();
//     }
//   }
// }
import 'package:flutter/material.dart';

class RecentTab extends StatelessWidget {
  const RecentTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}