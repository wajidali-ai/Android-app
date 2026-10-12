import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_theme.dart';
import '../core/constants/app_constants.dart';
import '../core/sync/sync_service.dart';
import 'bluetooth_printer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _shopkeeperController = TextEditingController();
  final _devicePrefixController = TextEditingController();
  final _supabaseUrlController = TextEditingController();
  final _supabaseKeyController = TextEditingController();

  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shopkeeperController.text = prefs.getString(AppConstants.keyShopkeeperName) ?? 'Main Counter';
      _devicePrefixController.text = prefs.getString(AppConstants.keyDeviceId) ?? 'D1';
      _supabaseUrlController.text = prefs.getString(AppConstants.keySupabaseUrl) ?? '';
      _supabaseKeyController.text = prefs.getString(AppConstants.keySupabaseAnonKey) ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyShopkeeperName, _shopkeeperController.text.trim());
    await prefs.setString(AppConstants.keyDeviceId, _devicePrefixController.text.trim().toUpperCase());
    await prefs.setString(AppConstants.keySupabaseUrl, _supabaseUrlController.text.trim());
    await prefs.setString(AppConstants.keySupabaseAnonKey, _supabaseKeyController.text.trim());

    setState(() => _isSaved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isSaved = false);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!')),
      );
    }
  }

  @override
  void dispose() {
    _shopkeeperController.dispose();
    _devicePrefixController.dispose();
    _supabaseUrlController.dispose();
    _supabaseKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Multi-Phone', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        children: [
          // 1. SHOPKEEPER & PHONE PROFILE
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.badge_outlined, color: AppTheme.brandPrimary),
                      SizedBox(width: 8),
                      Text(
                        'Shopkeeper & Device Identifier',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Each Android phone must have a unique device prefix to prevent duplicate bill numbers when syncing.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                  ),
                  const Divider(height: 20),
                  TextField(
                    controller: _shopkeeperController,
                    decoration: const InputDecoration(
                      labelText: 'Current Shopkeeper Name',
                      hintText: 'e.g. Rehan / Main Counter',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextField(
                    controller: _devicePrefixController,
                    decoration: const InputDecoration(
                      labelText: 'Device Code (e.g. D1, D2, P1)',
                      hintText: 'D1',
                      helperText: 'Bills will be numbered like MC-D1-YYYYMMDD-0001',
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spaceMd),

          // 2. CLOUD SYNCHRONIZATION (SUPABASE)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.cloud_sync_outlined, color: AppTheme.brandPrimary),
                          SizedBox(width: 8),
                          Text(
                            'Supabase Cloud Database',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: sync.isOnline ? AppTheme.brandSuccess.withOpacity(0.12) : Colors.grey.shade200,
                          borderRadius: AppTheme.radiusPill,
                        ),
                        child: Text(
                          sync.isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: sync.isOnline ? AppTheme.brandSuccess : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  Text(
                    'Pending offline queue: ${sync.pendingCount} bills waiting to sync.',
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (sync.lastSyncTime != null)
                    Text(
                      'Last synced: ${DateFormat("dd-MMM hh:mm a").format(sync.lastSyncTime!)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight),
                    ),
                  const Divider(height: 24),
                  TextField(
                    controller: _supabaseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Supabase Project URL',
                      hintText: 'https://xyzcompany.supabase.co',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  TextField(
                    controller: _supabaseKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Supabase Anon Public Key',
                      hintText: 'eyJhbGciOiJIUzI1NiIsInR5cCI6...',
                      isDense: true,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPrimary,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    onPressed: sync.isSyncing ? null : () => sync.syncAllPending(),
                    icon: sync.isSyncing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync, color: Colors.white),
                    label: Text(
                      sync.isSyncing ? 'Synchronizing...' : 'Sync Now with Cloud',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spaceMd),

          // 3. PRINTER SHORTCUT
          Card(
            child: ListTile(
              leading: const Icon(Icons.print, color: AppTheme.brandPrimary),
              title: const Text('Bluetooth Thermal Printer', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Configure ESC/POS printer, test print, and paper size (58mm/80mm)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BluetoothPrinterScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: AppTheme.spaceXl),

          // SAVE ALL BUTTON
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandSuccess,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
            ),
            onPressed: _saveSettings,
            child: const Text(
              'Save Profile & Settings',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
