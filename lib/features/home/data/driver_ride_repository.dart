import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DriverRideRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DriverRideRepository(this._firestore, this._auth);

  /// ───────────── Subscriptions & State ─────────────
  StreamSubscription<QuerySnapshot>? newRideSubscription;
  StreamSubscription<DocumentSnapshot>? activeRideSubscription;
  
  // 🔥 Keeps track of rides this driver rejected so they don't pop up again
  final Set<String> _locallyRejectedRides = {}; 

  /// ───────────── 1. FIND NEW RIDE (DYNAMIC) ─────────────
  /// Listens for rides matching the driver's vehicle type
  Future<void> listenForRideRequests({
    required void Function(String rideId, Map<String, dynamic> data) onRideFound,
  }) async {
    final driverId = _auth.currentUser?.uid;
    if (driverId == null) return;

    // STEP 1: Fetch this driver's details to know their vehicle type
    final driverDoc = await _firestore.collection('drivers').doc(driverId).get();
    
    if (!driverDoc.exists) {
      debugPrint("❌ DRIVER: Profile not found.");
      return;
    }

    // Assuming you save their vehicle type as 'vehicle_type'
    final String myVehicleType = driverDoc.data()?['vehicle_type'];

    debugPrint("🎧 DRIVER: Started listening for '$myVehicleType' rides...");

    newRideSubscription?.cancel();

    // STEP 2: Listen only to rides that match this driver's vehicle
    newRideSubscription = _firestore
        .collection('ride_requests')
        .where('status', isEqualTo: 'requested')
        .where('serviceType', isEqualTo: myVehicleType) // 🔥 DYNAMIC MATCH
        .where('assignedDriverId', isNull: true)        // Not yet accepted
        .snapshots()
        .listen((snapshot) {
      
      if (snapshot.docs.isEmpty) return;

      // Find the first ride that this driver HAS NOT rejected
      for (var doc in snapshot.docs) {
        if (!_locallyRejectedRides.contains(doc.id)) {
          debugPrint("🔔 DRIVER: Found matching Ride ID: ${doc.id}");
          onRideFound(doc.id, doc.data());
          return; // Trigger UI and stop checking other docs for now
        }
      }
      
    }, onError: (e) {
      debugPrint("❌ DRIVER ERROR: $e");
    });
  }

  /// ───────────── 2. ACCEPT / REJECT ─────────────
  Future<void> acceptOrRejectRide({
    required String rideId,
    required bool accept,
  }) async {
    final driverId = _auth.currentUser?.uid;
    if (driverId == null) return;

    if (accept) {
      // 🛠️ FIX: Fetch the driver's actual name right before accepting
      final driverDoc = await _firestore.collection('drivers').doc(driverId).get();
      final String driverName = driverDoc.data()?['name'] ?? 'Partner'; // Fallback to 'Partner'

      // ⚠️ Use a Transaction to ensure no two drivers accept the same ride
      await _firestore.runTransaction((transaction) async {
        final rideRef = _firestore.collection('ride_requests').doc(rideId);
        final snapshot = await transaction.get(rideRef);

        if (!snapshot.exists) throw Exception("Ride no longer exists!");
        
        // Double-check it wasn't snatched by someone else
        if (snapshot.data()?['assignedDriverId'] != null) {
          throw Exception("Ride was already accepted by another driver.");
        }

        transaction.update(rideRef, {
          'status': 'accepted',
          'assignedDriverId': driverId,
          'assignedDriverName': driverName, // 👈 Now correctly passes the name
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });
      debugPrint("✅ Ride $rideId Accepted!");
      
    } else {
      // 🛠️ FIX: Restored the Reject logic so the array is updated
      debugPrint("🚫 Ride $rideId Rejected locally.");
      _locallyRejectedRides.add(rideId); // Ignore this ride in the stream
    }
  }

  /// ───────────── 4. START RIDE (Verify OTP) ─────────────
  Future<void> startRide(String rideId, String enteredOtp) async {
    final doc = await _firestore.collection('ride_requests').doc(rideId).get();

    if (!doc.exists) throw Exception("Ride not found");

    final data = doc.data()!;
    final storedOtp = data['rideOtp'].toString(); 

    if (enteredOtp == storedOtp) {
      await _firestore.collection('ride_requests').doc(rideId).update({
        'status': 'started',
        'startedAt': FieldValue.serverTimestamp(),
      });
    } else {
      throw Exception("Invalid OTP");
    }
  }

  /// ───────────── 5. COMPLETE RIDE ─────────────
  Future<void> endRide(String rideId) async {
    await _firestore.collection('ride_requests').doc(rideId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ───────────── CLEANUP ─────────────
  void stopListening() {
    newRideSubscription?.cancel();
    activeRideSubscription?.cancel();
    newRideSubscription = null;
    activeRideSubscription = null;
    _locallyRejectedRides.clear();
  }
}