import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/search_provider.dart';
import '../services/fcm_service.dart';
import '../services/remote_config_service.dart';
import '../services/dashboard_export_service.dart';
import '../services/analytics_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;
  String? _uploadUrl;
  String? _uploadError;

  static const _indigo      = Color(0xFF4F46E5);
  static const _indigoLight = Color(0xFFEEF2FF);
  static const _slate50    = Color(0xFFF8FAFC);
  static const _slate200    = Color(0xFFE2E8F0);
  static const _slate600    = Color(0xFF475569);
  static const _slate900    = Color(0xFF0F172A);

  Future<void> _handleSignOut() async {
    await AnalyticsService.logLogout();
    if (mounted) {
      context.read<SearchProvider>().setDeveloperMode(false);
    }
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _exportAndUploadReport(SearchProvider provider) async {
    final db = provider.dashboard;
    if (db == null) return;

    setState(() {
      _isUploading = true;
      _uploadUrl = null;
      _uploadError = null;
    });

    try {
      // 1. Log analytics event
      await AnalyticsService.logExportPdf(db.topic);

      // 2. Generate PDF bytes
      final pdfBytes = await DashboardExportService.generatePdf(db, provider.oaBreakdown);

      // 3. Upload to Firebase Storage
      final url = await DashboardExportService.uploadReportToFirebase(pdfBytes, db.topic);

      setState(() {
        _uploadUrl = url;
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _uploadError = 'Upload failed: $e';
        _isUploading = false;
      });
    }
  }

  void _triggerMockNotification() {
    FcmService.mockNotification(
      'Mock Alert: Highly Cited Publication!',
      'Deep learning trends in 2026 have surpassed previous citations averages by 45%.',
    );
    setState(() {}); // Refresh notification listing
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final provider = context.watch<SearchProvider>();

    return Scaffold(
      backgroundColor: _slate50,
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        backgroundColor: _indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── USER PROFILE CARD ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _slate200),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: _indigoLight,
                    backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                    child: user?.photoURL == null
                        ? const Icon(Icons.person, size: 36, color: _indigo)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'Developer Account',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'No email associated',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _slate600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _handleSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── REMOTE CONFIG DISPLAY ──────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings_suggest, color: _indigo),
                      SizedBox(width: 8),
                      Text(
                        'Remote Configurations',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _slate900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Max Journals Displayed', style: TextStyle(fontSize: 13, color: _slate600)),
                      Text(
                        '${RemoteConfigService.maxJournalsDisplayed}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: _indigo),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Max Keywords Displayed', style: TextStyle(fontSize: 13, color: _slate600)),
                      Text(
                        '${RemoteConfigService.maxKeywordsDisplayed}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: _indigo),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── REPORT EXPORT & STORAGE UPLOAD ─────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_upload_outlined, color: _indigo),
                      SizedBox(width: 8),
                      Text(
                        'Export Analytics to Cloud',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _slate900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (provider.currentTopic.isEmpty || provider.dashboard == null)
                    const Text(
                      'Please perform a search first on the Home screen to enable exporting data.',
                      style: TextStyle(color: _slate600, fontSize: 13),
                    )
                  else ...[
                    Text(
                      'Generate a PDF report for topic "${provider.currentTopic}" and save it directly to Firebase Cloud Storage.',
                      style: const TextStyle(color: _slate600, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    if (_isUploading)
                      const Center(
                        child: CircularProgressIndicator(color: _indigo),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _exportAndUploadReport(provider),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export & Upload PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    if (_uploadUrl != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Successfully Uploaded to Storage:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              _uploadUrl!,
                              style: TextStyle(fontSize: 11, color: Colors.green.shade900),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _uploadUrl!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Link copied to clipboard')),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 14),
                                  label: const Text('Copy', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.parse(_uploadUrl!);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    }
                                  },
                                  icon: const Icon(Icons.open_in_new, size: 14),
                                  label: const Text('Open', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_uploadError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _uploadError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── CRASHLYTICS DEMO ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bug_report_outlined, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Firebase Crashlytics Demo',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _slate900),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            try {
                              throw Exception('Handled Exception: User triggered Exception in ProfileScreen');
                            } catch (e, stack) {
                              FirebaseCrashlytics.instance.recordError(e, stack);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Handled error recorded by Crashlytics')),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Record Error'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Induce app crash
                            FirebaseCrashlytics.instance.crash();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Force Crash'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── FCM NOTIFICATION CENTER ────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          ValueListenableBuilder<int>(
                            valueListenable: FcmService.notificationCount,
                            builder: (context, count, _) {
                              return Badge(
                                label: Text('$count'),
                                isLabelVisible: count > 0,
                                child: const Icon(Icons.notifications_active_outlined, color: _indigo),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Notification Center',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _slate900),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: _slate600, size: 20),
                        tooltip: 'Clear All',
                        onPressed: () async {
                          await FcmService.clearNotifications();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _triggerMockNotification,
                    icon: const Icon(Icons.add_alert_rounded),
                    label: const Text('Trigger Test Notification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade50,
                      foregroundColor: Colors.amber.shade900,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (FcmService.notifications.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No notifications received yet.',
                          style: TextStyle(color: _slate600, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: FcmService.notifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, idx) {
                        final notif = FcmService.notifications[idx];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            notif.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _slate900),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(notif.body, style: const TextStyle(fontSize: 12, color: _slate600)),
                              const SizedBox(height: 4),
                              Text(
                                '${notif.receivedAt.hour.toString().padLeft(2, '0')}:${notif.receivedAt.minute.toString().padLeft(2, '0')} - ${notif.receivedAt.day}/${notif.receivedAt.month}',
                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
