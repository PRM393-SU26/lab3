import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/search_provider.dart';
import '../services/fcm_service.dart';
import '../services/remote_config_service.dart';
import '../services/dashboard_export_service.dart';
import '../services/analytics_service.dart';
import '../providers/reading_list_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;
  String? _uploadUrl;
  String? _uploadError;
  Future<void> _handleSignOut() async {
    await AnalyticsService.logLogout();
    if (mounted) {
      context.read<SearchProvider>().setDeveloperMode(false);
    }
    await FirebaseAuth.instance.signOut();
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (e) {
      debugPrint("Google disconnect error: $e");
    }
    if (mounted) {
      context.read<ReadingListProvider>().load();
    }
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
      final pdfBytes = await DashboardExportService.generatePdf(
        db,
        provider.oaBreakdown,
      );

      // 3. Upload to Firebase Storage
      final url = await DashboardExportService.uploadReportToFirebase(
        pdfBytes,
        db.topic,
      );

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text('Profile & Settings')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // ── USER PROFILE CARD ──────────────────────────────
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? Icon(
                            Icons.person,
                            size: 36,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                  SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'Developer Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    user?.email ?? 'No email associated',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _handleSignOut,
                    icon: Icon(Icons.logout),
                    label: Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // ── REMOTE CONFIG DISPLAY ──────────────────────────
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.settings_suggest,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Remote Configurations',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Max Journals Displayed',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${RemoteConfigService.maxJournalsDisplayed}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Max Keywords Displayed',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${RemoteConfigService.maxKeywordsDisplayed}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // ── REPORT EXPORT & STORAGE UPLOAD ─────────────────
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Export Analytics to Cloud',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  if (provider.currentTopic.isEmpty ||
                      provider.dashboard == null)
                    Text(
                      'Please perform a search first on the Home screen to enable exporting data.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    )
                  else ...[
                    Text(
                      'Generate a PDF report for topic "${provider.currentTopic}" and save it directly to Firebase Cloud Storage.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 16),
                    if (_isUploading)
                      Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _exportAndUploadReport(provider),
                        icon: Icon(Icons.picture_as_pdf),
                        label: Text('Export & Upload PDF'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    if (_uploadUrl != null) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Successfully Uploaded to Storage:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 4),
                            SelectableText(
                              _uploadUrl!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.green.shade900,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: _uploadUrl!),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Link copied to clipboard',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.copy, size: 14),
                                  label: Text(
                                    'Copy',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                                SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () async {
                                    final uri = Uri.parse(_uploadUrl!);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                  icon: Icon(Icons.open_in_new, size: 14),
                                  label: Text(
                                    'Open',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_uploadError != null) ...[
                      SizedBox(height: 12),
                      Text(
                        _uploadError!,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            SizedBox(height: 20),

            // ── CRASHLYTICS DEMO ───────────────────────────────
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bug_report_outlined, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Firebase Crashlytics Demo',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            try {
                              throw Exception(
                                'Handled Exception: User triggered Exception in ProfileScreen',
                              );
                            } catch (e, stack) {
                              FirebaseCrashlytics.instance.recordError(
                                e,
                                stack,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Handled error recorded by Crashlytics',
                                  ),
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Record Error'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Induce app crash
                            FirebaseCrashlytics.instance.crash();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Force Crash'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // ── FCM NOTIFICATION CENTER ────────────────────────
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
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
                                child: Icon(
                                  Icons.notifications_active_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Notification Center',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        tooltip: 'Clear All',
                        onPressed: () async {
                          await FcmService.clearNotifications();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _triggerMockNotification,
                    icon: Icon(Icons.add_alert_rounded),
                    label: Text('Trigger Test Notification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade50,
                      foregroundColor: Colors.amber.shade900,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  if (FcmService.notifications.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No notifications received yet.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: FcmService.notifications.length,
                      separatorBuilder: (_, _) => Divider(height: 16),
                      itemBuilder: (context, idx) {
                        final notif = FcmService.notifications[idx];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            notif.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                notif.body,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${notif.receivedAt.hour.toString().padLeft(2, '0')}:${notif.receivedAt.minute.toString().padLeft(2, '0')} - ${notif.receivedAt.day}/${notif.receivedAt.month}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
