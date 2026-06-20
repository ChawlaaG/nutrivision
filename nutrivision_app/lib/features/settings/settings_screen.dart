import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/data_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DataService _dataService = DataService();
  bool _isMetric = true;
  bool _isDarkMode = true;
  bool _notifyBreakfast = true;
  bool _notifyLunch = true;
  bool _notifyDinner = true;
  bool _notifyWater = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMetric = prefs.getBool('pref_is_metric') ?? true;
      _isDarkMode = prefs.getBool('pref_is_dark_mode') ?? true;
      _notifyBreakfast = prefs.getBool('pref_notify_breakfast') ?? true;
      _notifyLunch = prefs.getBool('pref_notify_lunch') ?? true;
      _notifyDinner = prefs.getBool('pref_notify_dinner') ?? true;
      _notifyWater = prefs.getBool('pref_notify_water') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'pref_is_metric') _isMetric = value;
      if (key == 'pref_is_dark_mode') _isDarkMode = value;
      if (key == 'pref_notify_breakfast') _notifyBreakfast = value;
      if (key == 'pref_notify_lunch') _notifyLunch = value;
      if (key == 'pref_notify_dinner') _notifyDinner = value;
      if (key == 'pref_notify_water') _notifyWater = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('App Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('Preferences'),
          _buildSwitchTile(
            'Use Metric Units (kg, ml)',
            'Toggle off for Imperial (lbs, oz)',
            _isMetric,
            (val) => _saveSetting('pref_is_metric', val),
          ),
          _buildSwitchTile(
            'Dark Mode',
            'Use dark theme for the app',
            _isDarkMode,
            (val) => _saveSetting('pref_is_dark_mode', val),
          ),
          const Gap(24),

          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            'Breakfast Reminder',
            '9:00 AM',
            _notifyBreakfast,
            (val) => _saveSetting('pref_notify_breakfast', val),
          ),
          _buildSwitchTile(
            'Lunch Reminder',
            '1:00 PM',
            _notifyLunch,
            (val) => _saveSetting('pref_notify_lunch', val),
          ),
          _buildSwitchTile(
            'Dinner Reminder',
            '8:00 PM',
            _notifyDinner,
            (val) => _saveSetting('pref_notify_dinner', val),
          ),
          _buildSwitchTile(
            'Hydration Check',
            '3:00 PM',
            _notifyWater,
            (val) => _saveSetting('pref_notify_water', val),
          ),
          const Gap(24),

          _buildSectionHeader('Data Management'),
          _buildActionTile(
            Icons.download,
            'Export Data to CSV',
            'Save your logs to a file',
            () async {
              final messenger = ScaffoldMessenger.of(context);
              await _dataService.exportData();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Data exported successfully')),
                );
              }
            },
          ),
          _buildActionTile(
            Icons.upload,
            'Import Data from CSV',
            'Restore logs from a file',
            () async {
              final messenger = ScaffoldMessenger.of(context);
              final success = await _dataService.importData();
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Data imported successfully'
                        : 'Import failed or cancelled'),
                  ),
                );
              }
            },
          ),
          const Gap(24),

          _buildSectionHeader('About'),
          const ListTile(
            title: Text('Version', style: TextStyle(color: Colors.white)),
            subtitle: Text('1.0.0 (Production Build)',
                style: TextStyle(color: Colors.grey)),
          ),
          ListTile(
            title: const Text('Privacy Policy', style: TextStyle(color: Colors.white)),
            onTap: () {
              // Open URL
            },
            trailing: const Icon(Icons.open_in_new, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.green,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        activeThumbColor: Colors.green,
      ),
    );
  }

  Widget _buildActionTile(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
