import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RecentTab extends StatelessWidget {
  const RecentTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8), // Light grey background for contrast
      appBar: AppBar(
        title: const Text("Trip History", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Date Filter Badge
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Center(
              child: Text(
                DateFormat('MMM yyyy').format(DateTime.now()),
                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: user != null
            ? FirebaseFirestore.instance
                .collection('ride_requests')
                .where('assignedDriverId', isEqualTo: user.uid) // Ensure we verify ASSIGNED driver
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots()
            : Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final ride = snapshot.data!.docs[index];
              final data = ride.data() as Map<String, dynamic>;
              return _RideCard(ride: data);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.history_toggle_off, size: 60, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(
            'No rides yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            'Completed trips will appear here.',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final Map<String, dynamic> ride;

  const _RideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    // Safely extract data
    final status = ride['status']?.toString() ?? 'unknown';
    final createdAt = (ride['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    // Price Formatting
    final priceVal = ride['estimatedPrice'] ?? 0;
    final amount = NumberFormat.currency(symbol: '₹', decimalDigits: 0).format(priceVal);

    // Addresses
    final pickup = ride['pickup'] ?? ride['pickupAddress'] ?? 'Unknown Pickup';
    final drop = ride['drop'] ?? ride['dropAddress'] ?? 'Unknown Drop';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Header: Date & Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEE, dd MMM • hh:mm a').format(createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  amount,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),

            // 2. Timeline (Pickup -> Drop)
            IntrinsicHeight(
              child: Row(
                children: [
                  // Timeline Line Column
                  Column(
                    children: [
                      const Icon(Icons.circle, size: 10, color: Colors.green),
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey.shade200,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                      const Icon(Icons.square, size: 10, color: Colors.redAccent),
                    ],
                  ),
                  const SizedBox(width: 12),
                  
                  // Address Text Column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAddressText("Pickup", pickup),
                        const SizedBox(height: 16),
                        _buildAddressText("Drop-off", drop),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Footer: Status & Distance
            Row(
              children: [
                _buildStatusChip(status),
                const Spacer(),
                const Icon(Icons.route, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${ride['distance']?.toStringAsFixed(1) ?? '1.2'} km',
                  style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressText(String label, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(address, 
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
          maxLines: 1, 
          overflow: TextOverflow.ellipsis
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'completed':
        bg = Colors.green.shade50;
        text = Colors.green.shade700;
        label = "Completed";
        break;
      case 'cancelled':
        bg = Colors.red.shade50;
        text = Colors.red.shade700;
        label = "Cancelled";
        break;
      case 'started':
      case 'arrived':
        bg = Colors.orange.shade50;
        text = Colors.orange.shade800;
        label = "In Progress";
        break;
      default:
        bg = Colors.grey.shade100;
        text = Colors.grey.shade700;
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}