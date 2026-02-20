import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditDriverProfilePage extends StatefulWidget {
  final Map<String, dynamic>? currentData;

  const EditDriverProfilePage({super.key, this.currentData});

  @override
  State<EditDriverProfilePage> createState() => _EditDriverProfilePageState();
}

class _EditDriverProfilePageState extends State<EditDriverProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentData?['name'] ?? '');
    _phoneController = TextEditingController(text: widget.currentData?['phone'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('drivers').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          // 'updated_at': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        Navigator.pop(context); // Go back to profile page
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Update your details", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 30),
              
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value!.isEmpty ? "Name cannot be empty" : null,
              ),
              const SizedBox(height: 20),

              // Phone Field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value!.length < 10 ? "Enter valid phone number" : null,
              ),
              
              const Spacer(),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : const Text("Save Changes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}