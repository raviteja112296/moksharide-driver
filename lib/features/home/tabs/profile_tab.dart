// lib/features/home/tabs/profile_tab.dart

import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:moksharide_driver/features/auth/driver_signin_page.dart';
import 'package:image_picker/image_picker.dart'; 

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _driverData;
  bool _isLoading = true;
  bool _isUploading = false; 

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
      setState(() {
        _driverData = doc.data();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // 🔥 LOGIC: Update Firestore Status Only (Simulation)
  Future<void> _pickAndUploadDocument(String docKey, String docTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: 160,
        child: Column(
          children: [
            const Text("Select Source", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sourceButton(Icons.camera_alt, "Camera", ImageSource.camera, ctx),
                _sourceButton(Icons.photo_library, "Gallery", ImageSource.gallery, ctx),
              ],
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source, imageQuality: 50);

      if (pickedFile == null) return;

      setState(() => _isUploading = true);
      await Future.delayed(const Duration(seconds: 1)); 

      // Update Firestore
      await FirebaseFirestore.instance.collection('drivers').doc(user.uid).update({
        docKey: 'verified', 
        '${docKey}_status': 'uploaded',
      });

      // Update UI
      setState(() {
        _driverData?[docKey] = 'verified'; 
        _isUploading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$docTitle uploaded successfully!'), backgroundColor: Colors.green),
      );

    } catch (e) {
      setState(() => _isUploading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _sourceButton(IconData icon, String label, ImageSource source, BuildContext ctx) {
    return InkWell(
      onTap: () => Navigator.pop(ctx, source),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.blueAccent),
          const SizedBox(height: 5),
          Text(label),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DriverSignInPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = (_driverData?['name'] ?? 'Driver').toString().split(' ').first;
    
    // Check if ALL documents are uploaded to show Verified Badge
    bool isVerified = 
        _driverData?['doc_aadhaar'] == 'verified' &&
        _driverData?['doc_license'] == 'verified' &&
        _driverData?['doc_rc'] == 'verified' &&
        _driverData?['doc_pan'] == 'verified';

    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // HEADER (Fixed Overflow issue + Added Badge Logic)
                      _buildProfileHeader(firstName, isVerified),

                      const SizedBox(height: 30),

                      _sectionTitle('Account'),
                      _infoTile(Icons.email, 'Email', FirebaseAuth.instance.currentUser?.email ?? ''),
                      _infoTile(Icons.phone, 'Phone', _driverData?['phone'] ?? 'Not set'),

                      const SizedBox(height: 30),

                      _sectionTitle('Documents'),
                      _documentCard('Aadhaar Card', Icons.badge, 'doc_aadhaar'),
                      _documentCard('Driving License', Icons.card_membership, 'doc_license'),
                      _documentCard('Vehicle RC', Icons.directions_car, 'doc_rc'),
                      _documentCard('PAN Card', Icons.credit_card, 'doc_pan'),

                      const SizedBox(height: 30),

                      _buildLogoutButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),

          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text("Uploading...", style: TextStyle(color: Colors.white, fontSize: 16))
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 🛠️ FIX: Removed fixed height, added padding
  // 🏅 NEW: Added Verified Badge
  Widget _buildProfileHeader(String firstName, bool isVerified) {
    return Container(
      width: double.infinity,
      // Removed fixed height: 230 to prevent overflow
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20), 
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 10))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  backgroundImage: _driverData?['profilePic'] != null 
                      ? NetworkImage(_driverData!['profilePic']) 
                      : const AssetImage('assets/images/driver_avatar.png') as ImageProvider,
                ),
                // 🏅 VERIFIED BADGE
                if (isVerified)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified, color: Colors.blue, size: 24),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  firstName,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.verified, color: Colors.greenAccent, size: 24)
                ]
              ],
            ),
            Text(
              FirebaseAuth.instance.currentUser?.email ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            if (isVerified)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: const Text("Verified Driver", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              )
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 24, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }

  Widget _documentCard(String title, IconData icon, String docKey) {
    bool isUploaded = _driverData?[docKey] != null && _driverData?[docKey].toString().isNotEmpty == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(
          isUploaded ? Icons.check_circle : icon, 
          size: 32, 
          color: isUploaded ? Colors.green : Colors.blueAccent
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          isUploaded ? 'Status: Uploaded' : 'Status: Pending',
          style: TextStyle(
            color: isUploaded ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isUploaded ? Colors.green.shade500 : Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _pickAndUploadDocument(docKey, title),
          child: Text(isUploaded ? 'Update' : 'Upload'),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _showLogoutDialog,
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text('Logout', style: TextStyle(fontSize: 18, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}