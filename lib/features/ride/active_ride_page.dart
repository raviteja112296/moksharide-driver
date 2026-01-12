import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/fare_calculator.dart';

class RideModel {
  final String id;
  final String pickupLocation;
  final String dropLocation;
  final double distance;
  final double price;
  final Map<String, dynamic> data;

  RideModel({
    required this.id,
    required this.pickupLocation,
    required this.dropLocation,
    required this.distance,
    required this.price,
    required this.data,
  });

  RideModel.fromFirestore(String id, Map<String, dynamic> data)
      : this(
          id: id,
          data: data,
          pickupLocation: data['pickup'] ?? 'Unknown pickup',
          dropLocation: data['dropoff'] ?? 'Unknown dropoff',
          distance: (data['distance'] ?? 0).toDouble(),
          price: FareCalculator.calculateFare((data['distance'] ?? 0).toDouble()),
        );
}

class ActiveRidePage extends StatelessWidget {
  final RideModel ride;

  const ActiveRidePage({Key? key, required this.ride}) : super(key: key);

  Future<void> _completeRide(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('ride_requests')
          .doc(ride.id)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      Navigator.pushReplacementNamed(context, '/driver-home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete ride: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Active Ride'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_taxi, color: Colors.green, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Ride in Progress',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                _buildLocationRow(
                  'Pickup',
                  ride.pickupLocation,
                  Icons.location_on,
                  Colors.green,
                ),
                SizedBox(height: 16),
                _buildLocationRow(
                  'Dropoff',
                  ride.dropLocation,
                  Icons.flag,
                  Colors.orange,
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${ride.distance.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      '₹${ride.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _completeRide(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'COMPLETE RIDE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(String title, String location, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                location,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
