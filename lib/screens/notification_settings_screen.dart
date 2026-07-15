import 'package:flutter/material.dart';

import '../services/notification_prefs_service.dart';
import '../services/analytics_service.dart';

/// Settings screen that lets users control which notification types they
/// receive, set quiet hours, and configure daily limits.
///
/// All changes are persisted to Firestore at
/// `users/{uid}.notification_prefs` via [NotificationPrefsService].
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _loading = true;
  Map<String, dynamic> _prefs = {};

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await NotificationPrefsService.getPrefs();
    if (mounted) {
      setState(() {
        _prefs = prefs;
        _loading = false;
      });
    }
  }

  Future<void> _togglePref(String key, bool value) async {
    setState(() => _prefs[key] = value);
    await NotificationPrefsService.updatePref(key, value);
    await AnalyticsService.logNotificationPrefsChanged(
      setting: key,
      newValue: value,
    );
  }

  Future<void> _setQuietHours(String key, int hour) async {
    setState(() => _prefs[key] = hour);
    await NotificationPrefsService.updatePref(key, hour);
  }

  Future<void> _setMaxPerDay(int value) async {
    setState(() => _prefs['max_per_day'] = value);
    await NotificationPrefsService.updatePref('max_per_day', value);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // ── Master toggle ─────────────────────────────
                _buildSectionHeader('General'),
                SwitchListTile(
                  title: const Text('Enable notifications'),
                  subtitle:
                      const Text('Master toggle for all push notifications'),
                  value: _prefs['enabled'] == true,
                  onChanged: (v) => _togglePref('enabled', v),
                  activeColor: cs.primary,
                ),
                const Divider(),

                // ── Notification types ────────────────────────
                _buildSectionHeader('Notification Types'),
                SwitchListTile(
                  title: const Text('🔥 Trending topics'),
                  subtitle: const Text(
                      'Alerts when a research topic is surging in publications'),
                  value: _prefs['trending_topics'] == true,
                  onChanged: _prefs['enabled'] == true
                      ? (v) => _togglePref('trending_topics', v)
                      : null,
                  activeColor: cs.primary,
                ),
                SwitchListTile(
                  title: const Text('📊 Interest updates'),
                  subtitle: const Text(
                      'Updates on topics you frequently search or view'),
                  value: _prefs['interest_updates'] == true,
                  onChanged: _prefs['enabled'] == true
                      ? (v) => _togglePref('interest_updates', v)
                      : null,
                  activeColor: cs.primary,
                ),
                SwitchListTile(
                  title: const Text('📬 Weekly digest'),
                  subtitle: const Text(
                      'A weekly summary of trends in your research areas'),
                  value: _prefs['weekly_digest'] == true,
                  onChanged: _prefs['enabled'] == true
                      ? (v) => _togglePref('weekly_digest', v)
                      : null,
                  activeColor: cs.primary,
                ),
                SwitchListTile(
                  title: const Text('👋 Re-engagement'),
                  subtitle: const Text(
                      'Gentle reminders when you haven\'t used the app recently'),
                  value: _prefs['re_engagement'] == true,
                  onChanged: _prefs['enabled'] == true
                      ? (v) => _togglePref('re_engagement', v)
                      : null,
                  activeColor: cs.primary,
                ),
                const Divider(),

                // ── Quiet hours ───────────────────────────────
                _buildSectionHeader('Quiet Hours'),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    'No notifications will be sent between these hours.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                ListTile(
                  title: const Text('Start'),
                  trailing: DropdownButton<int>(
                    value: _prefs['quiet_hours_start'] as int? ?? 22,
                    items: List.generate(
                      24,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text('${i.toString().padLeft(2, '0')}:00'),
                      ),
                    ),
                    onChanged: _prefs['enabled'] == true
                        ? (v) {
                            if (v != null) _setQuietHours('quiet_hours_start', v);
                          }
                        : null,
                  ),
                ),
                ListTile(
                  title: const Text('End'),
                  trailing: DropdownButton<int>(
                    value: _prefs['quiet_hours_end'] as int? ?? 7,
                    items: List.generate(
                      24,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text('${i.toString().padLeft(2, '0')}:00'),
                      ),
                    ),
                    onChanged: _prefs['enabled'] == true
                        ? (v) {
                            if (v != null) _setQuietHours('quiet_hours_end', v);
                          }
                        : null,
                  ),
                ),
                const Divider(),

                // ── Daily limit ───────────────────────────────
                _buildSectionHeader('Daily Limit'),
                ListTile(
                  title: const Text('Max notifications per day'),
                  trailing: DropdownButton<int>(
                    value: (_prefs['max_per_day'] as int?) ?? 3,
                    items: [1, 2, 3, 5, 10]
                        .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text('$v'),
                            ))
                        .toList(),
                    onChanged: _prefs['enabled'] == true
                        ? (v) {
                            if (v != null) _setMaxPerDay(v);
                          }
                        : null,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
