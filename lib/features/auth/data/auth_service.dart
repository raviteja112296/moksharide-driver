import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:moksharide_driver/features/auth/driver_signin_page.dart';
import 'package:moksharide_driver/features/home/driver_home_page.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Existing Google sign-in method
Future<UserCredential> signInWithGoogle() async {
  final GoogleSignIn googleSignIn = GoogleSignIn();

  final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

  if (googleUser == null) {
    throw Exception("Google sign-in cancelled");
  }

  final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  return await FirebaseAuth.instance.signInWithCredential(credential);
}



  // In your AuthService class
Future<UserCredential> signInWithEmail(String email, String password) async {
  try {
    // main.dart handles reCAPTCHA bypass
    UserCredential result = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    
    print('✅ Email auth SUCCESS: ${result.user?.email}');
    return result;
  } on FirebaseAuthException catch (e) {
    print('❌ Auth: ${e.code} - ${e.message}');
    rethrow;
  }
}


  // Optional: register method
  Future<UserCredential> registerWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Optional: sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

Widget _checkAuthStatus() {
  final user = FirebaseAuth.instance.currentUser;
  print('🔍 App start: User ${user?.uid ?? "NULL"}');
  
  if (user != null) {
    return DriverHomePage(); // Auto-login
  }
  return DriverSignInPage(); // Show login
}