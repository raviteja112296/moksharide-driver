import 'package:flutter/material.dart';
import 'package:moksharide_driver/features/ride/driver_ride_repository.dart';

class RideStatusScreen extends StatelessWidget {
  final String rideId;

  const RideStatusScreen({super.key, required this.rideId});

  @override
  Widget build(BuildContext context) {
    final repo = DriverRideRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Ride'),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder(
        stream: repo.getRideById(rideId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info('Pickup', data['pickup']),
                _info('Drop', data['dropoff']),
                _info('Distance', '${data['distance']} km'),
                _info('Fare', '₹${data['price']}'),
                _info('Status', data['status']),

                const Spacer(),

                if (data['status'] == 'accepted')
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () async {
                        await repo.completeRide(rideId);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'COMPLETE RIDE',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _info(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
