import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverStatusService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> setOnlineStatus(bool isOnline) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('drivers').doc(user.uid).set({
        'isOnline': isOnline,
        'lastStatusUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Silently handle errors
    }
  }
}
