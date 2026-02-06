import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moksharide_driver/features/auth/driver_signin_page.dart'; // Ensure path is correct

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

  // 📥 Load Driver Data
  Future<void> _loadDriverProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
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
    } catch (e) {
      print("Error loading profile: $e");
      setState(() => _isLoading = false);
    }
  }

  // 🔥 CORE LOGIC: Check completeness and update 'documents' field
  Future<void> _pickAndUploadDocument(String docKey, String docTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Source Selection
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: 230, // Compact height
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const Text("Upload Document From", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
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
      // 2. Pick Image
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source, imageQuality: 50);

      if (pickedFile == null) return;

      setState(() => _isUploading = true);
      
      // Simulate Upload Time
      await Future.delayed(const Duration(seconds: 1));

      // 3. Update Individual Status to 'uploaded' (NOT verified yet)
      // This ensures we track which specific docs are done.
      await FirebaseFirestore.instance.collection('drivers').doc(user.uid).update({
        docKey: 'uploaded', 
        'updated_documents': FieldValue.serverTimestamp(),
      });

      // Update Local Data Immediately
      setState(() {
        _driverData ??= {};
        _driverData![docKey] = 'uploaded';
      });

      // 4. THE MASTER CHECK: Are ALL documents now uploaded?
      bool aadhaarDone = _driverData?['aadhaar'] == 'uploaded';
      bool licenseDone = _driverData?['license'] == 'uploaded';
      bool rcDone = _driverData?['RC'] == 'uploaded';
      bool panDone = _driverData?['PAN'] == 'uploaded';

      if (aadhaarDone && licenseDone && rcDone && panDone) {
        // 🎉 ALL DONE! Now we update the Master "documents" field to "verified"
        await FirebaseFirestore.instance.collection('drivers').doc(user.uid).update({
          'Documents': 'verified',
        });

        setState(() {
          _driverData!['Documents'] = 'verified';
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 All Documents Verified! You are now active.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Just show single success
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$docTitle Uploaded. Complete the rest to verify.'),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
      
      setState(() => _isUploading = false);

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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 30, color: Colors.blueAccent),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
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
    final firstName = (_driverData?['name'] ?? 'Partner').toString().split(' ').first;
    
    // ✅ NEW CHECK: Only rely on the master 'documents' field
    bool isFullyVerified = _driverData?['Documents'] == 'verified';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildProfileHeader(firstName, isFullyVerified),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _sectionTitle('Account Details'),
                            _infoTile(Icons.email_outlined, 'Email', FirebaseAuth.instance.currentUser?.email ?? 'Hidden'),
                            _infoTile(Icons.phone_iphone, 'Phone', _driverData?['phone'] ?? 'Not Linked'),
                            const SizedBox(height: 30),
                            _sectionTitle('Required Documents'),
                            _documentCard('Aadhaar Card', Icons.fingerprint, 'aadhaar'),
                            _documentCard('Driving License', Icons.drive_eta, 'license'),
                            _documentCard('Vehicle RC', Icons.description, 'RC'),
                            _documentCard('PAN Card', Icons.credit_card, 'PAN'),
                            const SizedBox(height: 40),
                            _buildLogoutButton(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text("Uploading...", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String firstName, bool isVerified) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _driverData?['profilePic'] != null 
                      ? NetworkImage(_driverData!['profilePic']) 
                      : null,
                  child: _driverData?['profilePic'] == null 
                      ? const Icon(Icons.person, size: 50, color: Colors.grey) 
                      : null,
                ),
              ),
              // Show Badge ONLY if 'documents' == 'verified'
              if (isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.verified, color: Colors.blue, size: 24),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            "Hello, $firstName",
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          // Show Tag ONLY if 'documents' == 'verified'
          if (isVerified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user, color: Colors.greenAccent, size: 16),
                  SizedBox(width: 6),
                  Text("Verified Partner", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          else 
            // Show Pending Tag if not yet verified
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.pending, color: Colors.orangeAccent, size: 16),
                  SizedBox(width: 6),
                  Text("Verification Pending", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: Colors.blue[800], borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.blue[800]),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _documentCard(String title, IconData icon, String docKey) {
    // 🛠️ FIX: Check if this specific doc is uploaded (locally or in master verified state)
    // It is "done" if the specific key is 'uploaded' OR if the whole account is 'verified'
    bool isUploaded = (_driverData?[docKey] == 'uploaded') || 
                      (_driverData?['documents'] == 'verified');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isUploaded ? Border.all(color: Colors.green.withOpacity(0.3)) : null,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isUploaded ? Colors.green[50] : Colors.orange[50],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isUploaded ? Icons.check : icon,
            color: isUploaded ? Colors.green : Colors.orange,
            size: 24,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(
          isUploaded ? 'Uploaded' : 'Pending',
          style: TextStyle(
            color: isUploaded ? Colors.green : Colors.orange,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: isUploaded 
            ? const Icon(Icons.check_circle, color: Colors.green)
            : SizedBox(
                height: 36,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () => _pickAndUploadDocument(docKey, title),
                  child: const Text("Upload"),
                ),
              ),
      ),
    );
  }
  
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _showLogoutDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[50],
          foregroundColor: Colors.red,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}