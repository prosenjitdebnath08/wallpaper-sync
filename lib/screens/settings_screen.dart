import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallpaper_sync/services/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _setHomeScreen = true;
  bool _setLockScreen = true;

  @override
  Widget build(BuildContext context) {
    final sync = Provider.of<SyncService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text(
              'Auto-Apply Wallpapers',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              'Instantly change wallpaper when an update is published from any device',
            ),
            value: sync.isAutoApplyEnabled,
            onChanged: (val) {
              sync.setAutoApply(val);
            },
          ),
          const Divider(),
          if (!Platform.isIOS && !Platform.isMacOS) ...[
            const ListTile(
              title: Text(
                'Android Display Targets',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            CheckboxListTile(
              title: const Text('Update Home Screen'),
              value: _setHomeScreen,
              onChanged: (val) => setState(() => _setHomeScreen = val ?? true),
            ),
            CheckboxListTile(
              title: const Text('Update Lock Screen'),
              value: _setLockScreen,
              onChanged: (val) => setState(() => _setLockScreen = val ?? true),
            ),
            const Divider(),
          ],
          if (Platform.isIOS) ...[
            ListTile(
              leading: const Icon(Icons.bolt, color: Colors.amber),
              title: const Text(
                'iOS Zero-Tap Automation Setup',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Configure Apple Shortcuts Personal Automation to update your iPhone screen without manual taps.',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showIosAutomationDialog(context);
              },
            ),
            const Divider(),
          ],
          if (Platform.isMacOS) ...[
            const ListTile(
              leading: Icon(Icons.desktop_mac),
              title: Text(
                'macOS Background Service',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Runs silently in the status menu bar and updates the desktop picture on all monitors automatically.',
              ),
            ),
            const Divider(),
          ],
          const ListTile(
            title: Text(
              'About Wallpaper Sync',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Version 1.0.0 (Multi-platform: macOS, iOS, Android)'),
          ),
        ],
      ),
    );
  }

  void _showIosAutomationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('iOS Zero-Tap Automation'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Because Apple restricts 3rd-party apps from altering wallpapers silently, follow these 3 quick steps in iOS Shortcuts:',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '1. Open the built-in "Shortcuts" app on iPhone.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '2. Go to the "Automation" tab -> Tap "+" (New Automation).',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text(
                '3. Choose "App" -> Select "Wallpaper Sync" -> "Is Closed" or "When I Receive Notification" -> Add Action "Set Wallpaper" pointing to the app\'s shared active wallpaper.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'Turn OFF "Ask Before Running" and your iPhone wallpaper will update completely automatically!',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
