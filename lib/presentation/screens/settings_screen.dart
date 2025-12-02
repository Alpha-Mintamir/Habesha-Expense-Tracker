import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/pin_service.dart';
import '../providers/sms_providers.dart';
import 'debug_sms_screen.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final smsPermissions = ref.watch(smsPermissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Appearance Section
          _SectionHeader(title: 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: Text(
              themeMode == ThemeMode.dark
                  ? 'Dark theme enabled'
                  : themeMode == ThemeMode.light
                      ? 'Light theme enabled'
                      : 'System default',
            ),
            value: themeMode == ThemeMode.dark,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
            },
            secondary: const Icon(Icons.dark_mode),
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme Mode'),
            subtitle: Text(_getThemeModeText(themeMode)),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                }
              },
            ),
          ),
          const Divider(),

          // SMS & Permissions Section
          _SectionHeader(title: 'SMS & Permissions'),
          smsPermissions.when(
            data: (granted) => ListTile(
              leading: Icon(
                granted ? Icons.check_circle : Icons.error,
                color: granted ? Colors.green : Colors.red,
              ),
              title: const Text('SMS Permissions'),
              subtitle: Text(
                granted
                    ? 'Permissions granted - SMS tracking active'
                    : 'Permissions required for automatic transaction tracking',
              ),
              trailing: granted
                  ? null
                  : ElevatedButton(
                      onPressed: () async {
                        final result = await PermissionService.requestSmsPermissions();
                        ref.invalidate(smsPermissionsProvider);
                        if (result && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('SMS permissions granted'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: const Text('Grant'),
                    ),
            ),
            loading: () => const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Checking permissions...'),
            ),
            error: (err, _) => ListTile(
              leading: const Icon(Icons.error, color: Colors.red),
              title: const Text('Error checking permissions'),
              subtitle: Text('$err'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('SMS Debug & Status'),
            subtitle: const Text('View SMS parsing status and logs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebugSmsScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Resync Past SMS'),
            subtitle: const Text('Import past CBE messages again'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OnboardingScreen(),
                ),
              );
            },
          ),
          const Divider(),

          // Security Section
          _SectionHeader(title: 'Security'),
          FutureBuilder<bool>(
            future: _getPinStatus(),
            builder: (context, snapshot) {
              final hasPin = snapshot.data ?? false;
              return ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('PIN Lock'),
                subtitle: Text(hasPin ? 'PIN enabled' : 'Protect app with PIN'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPinSettings(context, hasPin),
              );
            },
          ),
          const Divider(),

          // About Section
          _SectionHeader(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('App Version'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('About'),
            subtitle: const Text('Habesha Expense Tracker - Offline transaction tracker'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Habesha Expense Tracker',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025',
              );
            },
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  Future<bool> _getPinStatus() async {
    final pinService = PinService();
    return await pinService.hasPin();
  }

  void _showPinSettings(BuildContext context, bool hasPin) {
    if (hasPin) {
      _showPinManagementDialog(context);
    } else {
      _showSetPinDialog(context);
    }
  }

  void _showSetPinDialog(BuildContext context) {
    final pinController1 = TextEditingController();
    final pinController2 = TextEditingController();
    final pinService = PinService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController1,
              decoration: const InputDecoration(
                labelText: 'Enter 6-digit PIN',
                hintText: '000000',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController2,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                hintText: '000000',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final pin1 = pinController1.text;
              final pin2 = pinController2.text;

              if (pin1.length != 6 || pin2.length != 6) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN must be 6 digits'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              if (pin1 != pin2) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PINs do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              final success = await pinService.setPin(pin1);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'PIN set successfully' : 'Failed to set PIN'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _showPinManagementDialog(BuildContext context) {
    final pinService = PinService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PIN Lock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Change PIN'),
              onTap: () {
                Navigator.pop(context);
                _showChangePinDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_open, color: Colors.red),
              title: const Text('Disable PIN'),
              onTap: () {
                Navigator.pop(context);
                _showDisablePinDialog(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog(BuildContext context) {
    final currentPinController = TextEditingController();
    final newPinController1 = TextEditingController();
    final newPinController2 = TextEditingController();
    final pinService = PinService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPinController,
              decoration: const InputDecoration(
                labelText: 'Current PIN',
                hintText: '000000',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPinController1,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                hintText: '000000',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPinController2,
              decoration: const InputDecoration(
                labelText: 'Confirm New PIN',
                hintText: '000000',
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final currentPin = currentPinController.text;
              final newPin1 = newPinController1.text;
              final newPin2 = newPinController2.text;

              if (newPin1.length != 6 || newPin2.length != 6) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN must be 6 digits'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              if (newPin1 != newPin2) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New PINs do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              final success = await pinService.changePin(currentPin, newPin1);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'PIN changed successfully' : 'Incorrect current PIN'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showDisablePinDialog(BuildContext context) {
    final pinController = TextEditingController();
    final pinService = PinService();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable PIN'),
        content: TextField(
          controller: pinController,
          decoration: const InputDecoration(
            labelText: 'Enter current PIN to disable',
            hintText: '000000',
          ),
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final pin = pinController.text;
              final success = await pinService.disablePin(pin);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'PIN disabled' : 'Incorrect PIN'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                setState(() {}); // Refresh to update PIN status
              }
            },
            child: const Text('Disable', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

