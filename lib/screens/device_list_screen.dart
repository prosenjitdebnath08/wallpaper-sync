import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallpaper_sync/models/device_model.dart';
import 'package:wallpaper_sync/services/auth_service.dart';
import 'package:wallpaper_sync/services/sync_service.dart';

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({super.key});

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'macos':
        return Icons.laptop_mac;
      case 'android':
        return Icons.phone_android;
      case 'ios':
        return Icons.phone_iphone;
      default:
        return Icons.devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final sync = Provider.of<SyncService>(context);
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Devices'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('devices')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No devices registered yet.'),
            );
          }

          final devices = snapshot.data!.docs
              .map((d) => DeviceModel.fromFirestore(d))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final dev = devices[index];
              final isCurrent = dev.deviceId == sync.deviceId;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCurrent ? Colors.blue : Colors.grey.shade800,
                  child: Icon(
                    _getPlatformIcon(dev.platform),
                    color: Colors.white,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      dev.deviceName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: const Text(
                          'THIS DEVICE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  'Platform: ${dev.platform.toUpperCase()} • Auto-sync: ${dev.autoApply ? "Enabled" : "Disabled"}',
                ),
                trailing: dev.autoApply
                    ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                    : const Icon(Icons.pause_circle_filled, color: Colors.orange, size: 20),
              );
            },
          );
        },
      ),
    );
  }
}
