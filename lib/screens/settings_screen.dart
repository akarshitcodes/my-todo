import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _selectedTheme;

  @override
  void initState() {
    super.initState();

    _selectedTheme = widget.themeMode;
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';

      case ThemeMode.light:
        return 'Light';

      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _changeTheme(ThemeMode mode) {
    setState(() {
      _selectedTheme = mode;
    });

    widget.onThemeModeChanged(mode);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _buildSectionTitle(context, 'Appearance'),

          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.palette_outlined,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Theme',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _themeLabel(_selectedTheme),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_rounded),
                        label: Text('System'),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_rounded),
                        label: Text('Light'),
                      ),
                      ButtonSegment<ThemeMode>(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_rounded),
                        label: Text('Dark'),
                      ),
                    ],
                    selected: {_selectedTheme},
                    onSelectionChanged: (selection) {
                      _changeTheme(selection.first);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          _buildSectionTitle(context, 'Task Preferences'),

          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                _buildSettingTile(
                  context,
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  subtitle: 'Task reminders and alerts',
                  onTap: () async {
                    try {
                      await NotificationService.instance.scheduleTestNotification();

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test notification scheduled.'),
                        ),
                      );
                    } catch (error) {
                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Notification failed: $error')),
                      );
                    }
                  },
                ),

                const Divider(height: 1, indent: 70),

                _buildSettingTile(
                  context,
                  icon: Icons.flag_outlined,
                  title: 'Default Priority',
                  subtitle: 'Choose the default priority for new tasks',
                  onTap: () {
                    _showComingSoon(
                      context,
                      'Default priority settings are coming soon.',
                    );
                  },
                ),

                const Divider(height: 1, indent: 70),

                _buildSettingTile(
                  context,
                  icon: Icons.cleaning_services_outlined,
                  title: 'Completed Tasks',
                  subtitle: 'Manage completed task behavior',
                  onTap: () {
                    _showComingSoon(
                      context,
                      'Completed task settings are coming soon.',
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          _buildSectionTitle(context, 'About'),

          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                _buildSettingTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'About To-Do',
                  subtitle: 'A simple to-do app',
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),

                const Divider(height: 1, indent: 70),

                _buildSettingTile(
                  context,
                  icon: Icons.code_rounded,
                  title: 'Technology',
                  subtitle: 'Flutter • Dart • SQLite',
                  onTap: null,
                ),

                const Divider(height: 1, indent: 70),

                _buildSettingTile(
                  context,
                  icon: Icons.numbers_rounded,
                  title: 'Version',
                  subtitle: '1.0.0',
                  onTap: null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          Center(
            child: Text(
              'Built by Akarshit Agrawal❤️',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      enabled: onTap != null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 21),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(subtitle),
      ),
      trailing: onTap != null ? const Icon(Icons.chevron_right_rounded) : null,
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'My To-Do',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.task_alt_rounded, size: 40),
      children: const [
        Text(
          'A To-Do application built with Flutter and SQLite. It helps you manage your tasks efficiently and stay organized. This app is designed to be simple, fast, and user-friendly, providing a seamless experience for task management.',
        ),
      ],
    );
  }
}
