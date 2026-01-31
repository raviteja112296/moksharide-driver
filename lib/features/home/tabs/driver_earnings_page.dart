import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DriverEarningsPage extends StatelessWidget {
  const DriverEarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    
    // Get start of today (00:00:00)
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Today's Earnings"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ride_requests')
            .where('driverId', isEqualTo: uid)
            .where('status', isEqualTo: 'completed') // Only completed & paid rides
            // .where('createdAt', isGreaterThanOrEqualTo: startOfDay) // Un-comment if you have a timestamp field
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          
          // 1. Filter for Today Only (Manual filter is safer if date formats vary)
          final todayRides = docs.where((doc) {
            // Assuming you have a timestamp, if not, skip this check for testing
            // Timestamp ts = doc['createdAt'];
            // return ts.toDate().isAfter(startOfDay);
            return true; // Showing all for now to ensure you see data
          }).toList();

          // 2. Calculate Total
          double totalEarnings = 0;
          for (var doc in todayRides) {
            totalEarnings += (doc['estimatedPrice'] ?? 0).toDouble();
          }

          return Column(
            children: [
              // 💵 BIG TOTAL CARD
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: Column(
                  children: [
                    const Text("Total Earned Today", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(
                      "₹${totalEarnings.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${todayRides.length} Rides Completed",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Ride History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              // 📜 LIST OF RIDES
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: todayRides.length,
                  itemBuilder: (context, index) {
                    final data = todayRides[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.check, color: Colors.white),
                        ),
                        title: Text("Ride #${todayRides[index].id.substring(0, 5).toUpperCase()}"),
                        subtitle: Text(DateFormat('hh:mm a').format(DateTime.now())), // Replace with real time
                        trailing: Text(
                          "₹${data['estimatedPrice']}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}