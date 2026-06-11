import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens external links (DOI resolver, etc.) in the system browser.
class LinkLauncher {
  LinkLauncher._();

  static String normalizeDoiUrl(String doi) {
    final trimmed = doi.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'https://doi.org/$trimmed';
  }

  static Future<void> openDoi(BuildContext context, String doi) async {
    final uri = Uri.parse(normalizeDoiUrl(doi));

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showError(context);
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context);
      }
    }
  }

  static void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Không thể mở liên kết DOI. Vui lòng thử lại.'),
      ),
    );
  }
}
