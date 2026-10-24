import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/app_settings.dart';
import 'services/settings_service.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final SettingsService _settingsService = SettingsService();

  AppSettings _settings = const AppSettings();
  bool _isLoading = true;
  Map<String, dynamic> _storageInfo = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final loadedSettings = await _settingsService.loadSettings();
      final storageInfo = await _settingsService.getStorageInfo();
      if (mounted) {
        setState(() {
          _settings = loadedSettings;
          _storageInfo = storageInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading settings: $e',
              style: GoogleFonts.jetBrainsMono(),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _updateSettings(AppSettings newSettings) async {
    setState(() {
      _settings = newSettings;
    });
    try {
      await _settingsService.saveSettings(newSettings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving setting: $e',
              style: GoogleFonts.jetBrainsMono(),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _pickReminderTime() async {
    // Parse current reminderTime (HH:mm)
    final parts = _settings.reminderTime.split(':');
    final initialHour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 9 : 9;
    final initialMinute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await _updateSettings(_settings.copyWith(reminderTime: formattedTime));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(milliseconds: 1500),
            content: Text(
              'Reminder time set to $formattedTime',
              style: GoogleFonts.jetBrainsMono(color: Colors.black),
            ),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }
    }
  }

  Future<void> _confirmResetDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
          title: Text(
            'Reset Database?',
            style: GoogleFonts.jetBrainsMono(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: Text(
            'This will clear all habit tracking history and reset all app settings back to default values in SQLite.',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.jetBrainsMono(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Reset All',
                style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _settingsService.clearAllDatabaseData();
        await _loadSettings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Database reset successfully!',
                style: GoogleFonts.jetBrainsMono(color: Colors.black),
              ),
              backgroundColor: Colors.greenAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error resetting database: $e',
                style: GoogleFonts.jetBrainsMono(),
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        shadowColor: Colors.black,
        elevation: 3,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.jetBrainsMono(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.greenAccent,
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              children: [
                // Section: Notifications & Reminders
                _buildSectionHeader('Notifications & Reminders'),
                _buildCard(
                  children: [
                    SwitchListTile(
                      activeThumbColor: Colors.green,
                      title: Text(
                        'Daily Reminder',
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        'Receive reminders to complete habits',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      value: _settings.notificationsEnabled,
                      onChanged: (val) {
                        _updateSettings(
                          _settings.copyWith(notificationsEnabled: val),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      enabled: _settings.notificationsEnabled,
                      title: Text(
                        'Reminder Time',
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        'Scheduled check-in alert',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _settings.notificationsEnabled
                              ? Colors.greenAccent
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: Text(
                          _settings.reminderTime,
                          style: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      onTap: _settings.notificationsEnabled
                          ? _pickReminderTime
                          : null,
                    ),
                  ],
                ),

                // Section: Preferences
                _buildSectionHeader('Preferences'),
                _buildCard(
                  children: [
                    SwitchListTile(
                      activeThumbColor: Colors.green,
                      title: Text(
                        'Dark Mode',
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        'Use dark theme interface',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      value: _settings.darkMode,
                      onChanged: (val) {
                        _updateSettings(
                          _settings.copyWith(darkMode: val),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      activeThumbColor: Colors.green,
                      title: Text(
                        'Sound Effects',
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        'Play sounds on habit completion',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      value: _settings.soundEffects,
                      onChanged: (val) {
                        _updateSettings(
                          _settings.copyWith(soundEffects: val),
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      activeThumbColor: Colors.green,
                      title: Text(
                        'Haptic Feedback',
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        'Vibrate on check-in and button presses',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      value: _settings.hapticFeedback,
                      onChanged: (val) {
                        _updateSettings(
                          _settings.copyWith(hapticFeedback: val),
                        );
                      },
                    ),
                  ],
                ),

                // Section: Goals
                _buildSectionHeader('Weekly Goals'),
                _buildCard(
                  children: [
                    ListTile(
                      title: Text(
                        'Weekly Target Days',
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        'Days per week you aim to finish habits',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      trailing: DropdownButton<int>(
                        value: _settings.weeklyGoal,
                        underline: const SizedBox(),
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 15,
                        ),
                        items: List.generate(7, (index) => index + 1)
                            .map(
                              (days) => DropdownMenuItem(
                                value: days,
                                child: Text('$days days'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _updateSettings(
                              _settings.copyWith(weeklyGoal: val),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),

                // Section: Storage Layer (SQLite)
                _buildSectionHeader('Database & Storage'),
                _buildCard(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.storage,
                        color: Colors.black87,
                      ),
                      title: Text(
                        'SQLite Engine',
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        'Database: ${_storageInfo['databaseName'] ?? 'habit_mastery.db'} (v${_storageInfo['version'] ?? 1})',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _storageInfo['isOpen'] == true
                                ? 'Connected'
                                : 'Ready',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(
                        Icons.folder_outlined,
                        color: Colors.black87,
                      ),
                      title: Text(
                        'Storage Path',
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        _storageInfo['path']?.toString() ?? 'Loading...',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete_forever, size: 20),
                        label: Text(
                          'Reset All Database Data',
                          style: GoogleFonts.jetBrainsMono(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: const BorderSide(color: Colors.black),
                          ),
                        ),
                        onPressed: _confirmResetDatabase,
                      ),
                    ),
                  ],
                ),

                // Section: App Information
                _buildSectionHeader('About'),
                _buildCard(
                  children: [
                    ListTile(
                      title: Text(
                        'Habit Mastery App',
                        style: GoogleFonts.jetBrainsMono(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Version 1.0.0+1 • SQLite Enabled',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
    );
  }
}
