import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A lightweight (id, displayName, count) entry used to build
/// "Dành cho bạn" (For You) suggestions.
class FrequentItem {
  final String id;
  final String displayName;
  final int count;

  FrequentItem({required this.id, required this.displayName, required this.count});
}

/// Generic on-device frequency tracker, keyed by a stable [id] but keeping
/// a human-readable [displayName]. Used to remember which journals or
/// keywords a user views most often, so screens like Journals/Keywords can
/// surface personalized "Dành cho bạn" suggestions the same way Home does
/// with search topics.
class ItemFrequencyService {
  final String storageKey;
  final int maxEntries;

  ItemFrequencyService({required this.storageKey, this.maxEntries = 30});

  Future<Map<String, dynamic>> _readRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeRaw(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, jsonEncode(data));
  }

  /// Records a view of [id]/[displayName], incrementing its count.
  Future<void> add(String id, String displayName) async {
    if (id.isEmpty) return;
    final data = await _readRaw();

    final existing = data[id] as Map<String, dynamic>?;
    final count = (existing?['count'] as num?)?.toInt() ?? 0;

    data[id] = {
      'name': displayName,
      'count': count + 1,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };

    // Trim to the most recently touched entries so storage doesn't grow
    // unbounded.
    if (data.length > maxEntries) {
      final sorted = data.entries.toList()
        ..sort((a, b) => ((b.value['ts'] as num?) ?? 0)
            .compareTo((a.value['ts'] as num?) ?? 0));
      final trimmed = <String, dynamic>{};
      for (final e in sorted.take(maxEntries)) {
        trimmed[e.key] = e.value;
      }
      await _writeRaw(trimmed);
      return;
    }

    await _writeRaw(data);
  }

  /// Returns the [limit] items with the highest view count, most frequent
  /// first. Ties are broken by most recently viewed.
  Future<List<FrequentItem>> getTopItems({int limit = 2}) async {
    final data = await _readRaw();
    if (data.isEmpty) return [];

    final items = data.entries
        .map((e) => FrequentItem(
              id: e.key,
              displayName: (e.value['name'] as String?) ?? e.key,
              count: (e.value['count'] as num?)?.toInt() ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return items.take(limit).toList();
  }

  /// Number of distinct items ever viewed (e.g. distinct journals).
  Future<int> distinctCount() async {
    final data = await _readRaw();
    return data.length;
  }

  /// Total number of views across all items (e.g. total journal opens,
  /// counting repeats).
  Future<int> totalViews() async {
    final data = await _readRaw();
    return data.values.fold<int>(
        0, (sum, v) => sum + ((v['count'] as num?)?.toInt() ?? 0));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}