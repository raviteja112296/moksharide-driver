// lib/features/home/tabs/profile_tab.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:moksharide_driver/features/auth/driver_signin_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _driverData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(user.uid)
        .get();

    if (doc.exists) {
      _driverData = doc.data();
    }

    setState(() => _isLoading = false);
  }

  /// 🔥 Logout Confirmation Dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(user.uid)
          .update({'isOnline': false});
    }

    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();

    if (!mounted) return;

    Navigator.pop(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DriverSignInPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName =
        (_driverData?['name'] ?? 'Ravi').toString().split(' ').first;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  /// 🔥 IMPROVED PROFILE HEADER
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: Container(
    height: 230,
    width: 400,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 16,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white,
              
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/images/driver_avatar.png'),
                ),
              

            ),
          ),
          const SizedBox(height: 14),
          Text(
            firstName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            FirebaseAuth.instance.currentUser?.email ?? '',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  ),
),



                  const SizedBox(height: 30),

                  /// 🔥 ACCOUNT INFO
                  _sectionTitle('Account'),
                  _infoTile(
                    Icons.email,
                    'Email',
                    FirebaseAuth.instance.currentUser?.email ?? '',
                  ),
                  _infoTile(
                    Icons.phone,
                    'Phone',
                    _driverData?['phone'] ?? 'Not set',
                  ),

                  const SizedBox(height: 30),

                  /// 🔥 DOCUMENTS
                  _sectionTitle('Documents'),
                  _documentCard('Aadhaar Card', Icons.badge),
                  _documentCard('Driving License', Icons.card_membership),
                  _documentCard('Vehicle RC', Icons.directions_car),
                  _documentCard('PAN Card', Icons.credit_card),

                  const SizedBox(height: 30),

                  /// 🔥 LOGOUT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Logout',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// 🔹 SECTION TITLE
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 24, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 INFO TILE
  Widget _infoTile(IconData icon, String label, String value) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }

  /// 🔹 DOCUMENT CARD
  Widget _documentCard(String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.blueAccent),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Status: Pending'),
        trailing: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title upload clicked')),
            );
          },
          child: const Text('Upload'),
        ),
      ),
    );
  }
}
