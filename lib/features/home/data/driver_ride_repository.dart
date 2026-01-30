import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DriverRideRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DriverRideRepository(this._firestore, this._auth);

  /// ───────────── Subscriptions ─────────────
  StreamSubscription<QuerySnapshot>? newRideSubscription;
  StreamSubscription<DocumentSnapshot>? activeRideSubscription;

  /// ───────────── 1. FIND NEW RIDE ─────────────
  /// Listens for rides with status 'waiting'
void listenForRideRequests({
    required void Function(String rideId, Map<String, dynamic> data) onRideFound,
  }) {
    final driverId = _auth.currentUser?.uid;
    if (driverId == null) return;

    print("🎧 DRIVER: Started listening for 'requested' rides..."); // DEBUG PRINT

    newRideSubscription?.cancel();

    newRideSubscription = _firestore
        .collection('ride_requests')
        .where('status', isEqualTo: 'requested') // 👈 CRITICAL: Must match User App
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      
      print("📡 DRIVER: Firestore event received. Docs: ${snapshot.docs.length}"); // DEBUG PRINT

      if (snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first;
      print("🔔 DRIVER: Found Ride ID: ${doc.id}"); // DEBUG PRINT
      
      onRideFound(doc.id, doc.data() as Map<String, dynamic>);
    }, onError: (e) {
      print("❌ DRIVER ERROR: $e");
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
      await _firestore.collection('ride_requests').doc(rideId).update({
        'status': 'accepted',
        'assignedDriverId': driverId,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // For MVP: Rejecting just keeps it 'waiting' but could add to a 'rejectedBy' list
      // For now, we won't cancel it so other drivers can see it.
      // Or if you want to explicitly cancel:
      // await _firestore.collection('ride_requests').doc(rideId).update({'status': 'cancelled'});
    }
  }

  /// ───────────── 3. DRIVER ARRIVED (🔥 NEW) ─────────────
  /// Tells the user the driver is at the pickup location
  Future<void> markDriverArrived(String rideId) async {
    await _firestore.collection('ride_requests').doc(rideId).update({
      'status': 'arrived',
      'arrivedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ───────────── 4. START RIDE (Verify OTP) ─────────────
  /// Renamed from verifyOtp to startRide to match UI call
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
  /// Renamed from completeRide to endRide to match UI call
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
  }
}