


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DriverRideRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// 🔴 Listen only NEW ride requests
  Stream<List<QueryDocumentSnapshot>> getPendingRides() {
    return _firestore
        .collection('ride_requests')
        .where('status', isEqualTo: 'pending') // 👈 VERY IMPORTANT
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  /// 🔴 Listen single ride (for bottom sheet)
  Stream<DocumentSnapshot> getRideById(String rideId) {
    return _firestore
        .collection('ride_requests')
        .doc(rideId)
        .snapshots();
  }

  /// ✅ SAFE ACCEPT (TRANSACTION)
Future<void> acceptRide(String rideId) async {
  final driver = _auth.currentUser;
  if (driver == null) {
    throw Exception('Driver not logged in');
  }

  final rideRef =
      FirebaseFirestore.instance.collection('ride_requests').doc(rideId);

  try {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(rideRef);

      if (!snapshot.exists) {
        throw Exception('Ride not found');
      }

      final data = snapshot.data() as Map<String, dynamic>;

      final String status = data['status'] ?? '';

      debugPrint('🚦 Ride status before accept: $status');

      // 🔒 Allow accept ONLY if still pending
      if (status != 'pending') {
        throw Exception('Ride already accepted or cancelled');
      }

      transaction.update(rideRef, {
        'status': 'accepted',
        'driverId': driver.uid,
        'acceptedAt': FieldValue.serverTimestamp(),

        // OPTIONAL (but recommended)
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    debugPrint('✅ Ride accepted successfully');
  } catch (e) {
    debugPrint('❌ acceptRide failed: $e');
    rethrow;
  }
}


  /// ✅ COMPLETE RIDE
  Future<void> completeRide(String rideId) async {
    await _firestore
        .collection('ride_requests')
        .doc(rideId)
        .update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ✅ DRIVER CANCEL (OPTIONAL)
  Future<void> cancelRideByDriver(String rideId) async {
    await _firestore
        .collection('ride_requests')
        .doc(rideId)
        .update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': 'driver',
    });
  }
  /// ✅ DRIVER CANCEL (OPTIONAL)
  Future<void> cancelRideByUser(String rideId) async {
    await _firestore
        .collection('ride_requests')
        .doc(rideId)
        .update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': 'user',
    });
  }
  Future<void> ignoreRide(String rideId) async {
  await FirebaseFirestore.instance
      .collection('ride_requests')
      .doc(rideId)
      .update({'status': 'cancelled', 'assignedDriver': null});
}


}
