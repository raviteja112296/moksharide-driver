import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moksharide_driver/features/home/driver_status_service.dart';
import '../../core/fare_calculator.dart';

class RideModel {
  final String id;
  final String pickupLocation;
  final String dropLocation;
  final double distance;
  final double price;
  final Map<String, dynamic> data;

  RideModel.fromFirestore(DocumentSnapshot doc)
      : id = doc.id,
        data = doc.data() as Map<String, dynamic>,
        pickupLocation = doc['pickup'] ?? 'Unknown pickup',
        dropLocation = doc['dropoff'] ?? 'Unknown dropoff',
        distance = (doc['distance'] ?? 0).toDouble(),
        price = FareCalculator.calculateFare((doc['distance'] ?? 0).toDouble());
}

class RideRequestPage extends StatelessWidget {
  final DriverStatusService _statusService = DriverStatusService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      appBar: AppBar(
        title: Text('Ride Requests'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ride_requests')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No ride requests available'),
                ],
              ),
            );
          }

          final rides = snapshot.data!.docs.map((doc) => RideModel.fromFirestore(doc)).toList();

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: rides.length,
            itemBuilder: (context, index) {
              final ride = rides[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ride.pickupLocation,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.flag, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ride.dropLocation,
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${ride.distance.toStringAsFixed(1)} km',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            '₹${ride.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('ride_requests')
                                  .doc(ride.id)
                                  .update({
                                'status': 'accepted',
                                'driverId': user.uid,
                                'acceptedAt': FieldValue.serverTimestamp(),
                              });
                              
                              // Navigate to active ride
                              Navigator.pushNamed(
                                context,
                                '/active-ride',
                                arguments: ride,
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to accept ride')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'ACCEPT RIDE',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
