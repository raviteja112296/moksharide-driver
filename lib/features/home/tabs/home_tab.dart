// lib/features/home/tabs/home_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:moksharide_driver/features/map/driver_map_container.dart';

class HomeTab extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onToggleOnline;

  /// 🔥 REQUIRED FOR MAP + OTP + RIDE FLOW
  final String? activeRideId;
  final String? activeRideStatus;

  const HomeTab({
    super.key,
    required this.isOnline,
    required this.onToggleOnline,
    required this.activeRideId, 
    required this.activeRideStatus, // ✅ FIX
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showQuickLabels(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _labelItem(
                    icon: Icons.local_offer,
                    title: 'Offers',
                    color: Colors.deepOrange,
                  ),
                  _labelItem(
                    icon: Icons.group_add,
                    title: 'Refer',
                    color: Colors.green,
                  ),
                  _labelItem(
                    icon: Icons.account_balance_wallet,
                    title: 'Earnings',
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _labelItem({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        toolbarHeight: 80,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E3C72).withOpacity(0.95),
                const Color(0xFF2A5298).withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: () => _showQuickLabels(context),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                FirebaseAuth.instance.currentUser?.email
                        ?.split('@')
                        .first ??
                    'Driver',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        actions: [
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              onToggleOnline();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOnline
                      ? [Colors.green, Colors.greenAccent]
                      : [Colors.grey, Colors.grey.shade600],
                ),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isOnline ? Colors.green : Colors.grey,
                        width: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOnline ? 'ONLINE' : 'OFFLINE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      /// 🔥 MAP + STACKED RIDE SHEET
      body: DriverMapContainer(
        isOnline: isOnline,
        activeRideId: activeRideId, // ✅ NOW WORKS
      ),
    );
  }
}
