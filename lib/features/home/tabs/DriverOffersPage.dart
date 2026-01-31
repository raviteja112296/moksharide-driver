import 'package:flutter/material.dart';

class DriverOffersPage extends StatelessWidget {
  const DriverOffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Your Offers")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildOfferCard(Colors.orange, "Complete 5 Rides", "Get ₹100 Bonus", "Expires Today"),
          _buildOfferCard(Colors.blue, "Morning Rush", "2x Earnings (8AM - 10AM)", "Active Now"),
          _buildOfferCard(Colors.green, "Refer a Friend", "Get ₹500 per referral", "Always Active"),
        ],
      ),
    );
  }

  Widget _buildOfferCard(Color color, String title, String subtitle, String status) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 6)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              Chip(label: Text(status, style: const TextStyle(color: Colors.white)), backgroundColor: color)
            ],
          ),
        ),
      ),
    );
  }
}