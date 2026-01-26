import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverRideRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DriverRideRepository(this._firestore, this._auth);

  /// ───────────── Subscriptions ─────────────
  StreamSubscription<QuerySnapshot>? newRideSubscription;
  StreamSubscription<DocumentSnapshot>? activeRideSubscription;

  /// ───────────── FIND NEW RIDE ─────────────
  /// Listens only for NEW ride requests
  void listenForRideRequests({
    required void Function(String rideId, Map<String, dynamic> data) onRideFound,
  }) {
    final driverId = _auth.currentUser?.uid;
    if (driverId == null) return;

    newRideSubscription?.cancel();

    newRideSubscription = _firestore
        .collection('ride_requests')
        .where('status', isEqualTo: 'requested')
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first;
      onRideFound(doc.id, doc.data());
    });
  }

  /// ───────────── ACCEPT / REJECT ─────────────
  Future<void> acceptOrRejectRide({
    required String rideId,
    required bool accept,
  }) async {
    final driverId = _auth.currentUser?.uid;
    if (driverId == null) return;

    await _firestore.collection('ride_requests').doc(rideId).update({
      'status': accept ? 'accepted' : 'cancelled',
      'assignedDriverId': accept ? driverId : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ───────────── LISTEN ACTIVE RIDE ─────────────
  /// Used for OTP → started → completed
  void listenToActiveRide({
    required String rideId,
    required void Function(Map<String, dynamic> data) onRideUpdated,
  }) {
    activeRideSubscription?.cancel();

    activeRideSubscription = _firestore
        .collection('ride_requests')
        .doc(rideId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      onRideUpdated(doc.data()!);
    });
  }

  /// ───────────── VERIFY OTP ─────────────
  /// Compares Firestore OTP with entered OTP
  Future<bool> verifyOtp({
    required String rideId,
    required String enteredOtp,
  }) async {
    final doc =
        await _firestore.collection('ride_requests').doc(rideId).get();

    if (!doc.exists) return false;

    final data = doc.data()!;
    final storedOtp = data['rideOtp']; // 🔑 generated in USER app

    if (enteredOtp == storedOtp) {
      await _firestore.collection('ride_requests').doc(rideId).update({
        'status': 'started',
        'startedAt': FieldValue.serverTimestamp(),
      });
      return true;
    }

    return false;
  }

  /// ───────────── COMPLETE RIDE ─────────────
  Future<void> completeRide(String rideId) async {
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
