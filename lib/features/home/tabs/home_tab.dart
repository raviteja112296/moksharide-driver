// lib/features/home/tabs/home_tab.dart - ✅ FULLY PERFECTED
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeTab extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onToggleOnline;

  const HomeTab({
    super.key,
    required this.isOnline,
    required this.onToggleOnline,
  });

  final LatLng _driverLocation = const LatLng(13.40024, 78.05225); // Chintamani

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
  onPressed: () {
    _showQuickLabels(context);
  },
),

        title: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Driver',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // 🔥 Theme toggle (optional)
          IconButton(
            icon: const Icon(Icons.dark_mode_outlined, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          
          // 🔥 ONLINE/OFFLINE PILL (Perfect sync with FAB)
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact(); // Premium feel
              onToggleOnline(); // Calls DriverHomePage _toggleOnlineStatus()
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isOnline
                      ? [Colors.green.withOpacity(0.9), Colors.greenAccent.withOpacity(0.7)]
                      : [Colors.grey.withOpacity(0.8), Colors.grey.shade600],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: isOnline ? Colors.green.withOpacity(0.4) : Colors.black26,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _driverLocation,
          initialZoom: 14,
          minZoom: 10,
          maxZoom: 18,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.moksharide.driver',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _driverLocation,
                width: 60,
                height: 60,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  transform: Matrix4.identity()..scale(isOnline ? 1.3 : 1.0),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isOnline
                            ? [Colors.green, Colors.greenAccent]
                            : [Colors.red, Colors.redAccent],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: isOnline ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
