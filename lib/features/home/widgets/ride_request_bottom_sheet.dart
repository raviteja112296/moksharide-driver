import 'package:flutter/material.dart';

class RideRequestBottomSheet extends StatelessWidget {
  final String pickup;
  final String drop;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const RideRequestBottomSheet({
    super.key,
    required this.pickup,
    required this.drop,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 440,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _handle(),

          const SizedBox(height: 12),

          Row(
            children: const [
              Icon(Icons.directions_car, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'New Ride Request',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _routeCard(),

          const Spacer(),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'REJECT',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'ACCEPT RIDE',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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

  // ───────── Handle ─────────
  Widget _handle() => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );

  // ───────── Route Card ─────────
  Widget _routeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          _locationRow(
            icon: Icons.my_location,
            color: Colors.green,
            label: "Pickup",
            text: pickup,
          ),

          const SizedBox(height: 12),

          _dottedDivider(),

          const SizedBox(height: 12),

          _locationRow(
            icon: Icons.location_on,
            color: Colors.red,
            label: "Drop",
            text: drop,
          ),
        ],
      ),
    );
  }

  // ───────── Location Row ─────────
  Widget _locationRow({
    required IconData icon,
    required Color color,
    required String label,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────── Divider ─────────
  Widget _dottedDivider() {
    return Row(
      children: List.generate(
        20,
        (index) => Expanded(
          child: Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}
