// lib/features/home/tabs/home_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moksharide_driver/features/home/tabs/DriverOffersPage.dart';
import 'package:share_plus/share_plus.dart'; 
import 'package:moksharide_driver/features/map/driver_map_container.dart';
import 'package:moksharide_driver/features/home/tabs/driver_earnings_page.dart';

class HomeTab extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onToggleOnline;
  final String? activeRideId;
  final String? activeRideStatus;

  const HomeTab({
    super.key,
    required this.isOnline,
    required this.onToggleOnline,
    required this.activeRideId, 
    required this.activeRideStatus,
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
                width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 1. OFFERS BUTTON
                  _labelItem(
                    context: context,
                    icon: Icons.local_offer,
                    title: 'Offers',
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.pop(context); // Close sheet
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverOffersPage()));
                    },
                  ),

                  // 2. REFER BUTTON (SHARE)
                  _labelItem(
                    context: context,
                    icon: Icons.group_add,
                    title: 'Refer',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      Share.share('Join Moksha Ride as a Driver and earn ₹500 bonus! Use my code: DRV123. Download now: https://moksharide.com');
                    },
                  ),

                  // 3. EARNINGS BUTTON
                  _labelItem(
                    context: context,
                    icon: Icons.account_balance_wallet,
                    title: 'Earnings',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverEarningsPage()));
                    },
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap, 
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 THE FIX: Calculate if the driver is currently on a ride
    bool isOnRide = activeRideId != null && 
                    activeRideId!.isNotEmpty && 
                    activeRideStatus != 'completed' &&
                    activeRideStatus != 'cancelled';
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
                style: const TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500),
              ),
              Text(
                FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'Driver',
                style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          // 🔥 THE LOCKED TOGGLE BUTTON
          GestureDetector(
            onTap: () {
              if (isOnRide) {
                // 🛑 DISABLED STATE: Block toggle and show message
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You cannot go offline during an active ride.'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                // ✅ ACTIVE STATE: Normal toggle
                HapticFeedback.heavyImpact();
                onToggleOnline();
              }
            },
            child: Opacity(
              opacity: isOnRide ? 0.7 : 1.0, // Dims the button if on a ride
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOnline ? [Colors.green, Colors.greenAccent] : [Colors.grey, Colors.grey.shade600],
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: isOnline ? Colors.green : Colors.grey, width: 2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(isOnline ? 'ONLINE' : 'OFFLINE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    
                    // 🔒 Show a small lock icon if the ride is active
                    if (isOnRide) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.lock, color: Colors.white, size: 14),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: DriverMapContainer(
        isOnline: isOnline,
        activeRideId: activeRideId,
      ),
    );
  }
}