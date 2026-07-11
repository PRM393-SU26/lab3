import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const _key = 'search_history';
  static const _freqKey = 'search_frequency';
  static const _maxEntries = 10;

  Future<List<String>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final items = await getAll();
    items.remove(trimmed);
    items.insert(0, trimmed);

    if (items.length > _maxEntries) {
      items.removeRange(_maxEntries, items.length);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, items);

    // Track how many times each topic has been searched, so the Home
    // screen can surface the user's most-searched topics (e.g. "AI",
    // "Algorithm") as personalized suggestions.
    await _incrementFrequency(trimmed);
  }

  Future<void> remove(String query) async {
    final items = await getAll();
    items.remove(query);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, items);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_freqKey);
  }

  Future<Map<String, int>> _getFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_freqKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _incrementFrequency(String query) async {
    // Normalize so "AI" and "ai" are counted as the same topic.
    final normalized = query.toLowerCase();
    final freq = await _getFrequency();
    freq[normalized] = (freq[normalized] ?? 0) + 1;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_freqKey, jsonEncode(freq));
  }

  /// Returns the [limit] topics the user has searched for most often, most
  /// frequent first. Ties are broken by most recently searched.
  Future<List<String>> getTopTopics({int limit = 3}) async {
    final freq = await _getFrequency();
    if (freq.isEmpty) return [];

    final recent = await getAll();
    // Map normalized -> best-cased display string (prefer the version
    // stored in recent history, which keeps the user's original casing).
    final display = <String, String>{};
    for (final r in recent) {
      display[r.toLowerCase()] = r;
    }

    final entries = freq.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        if (byCount != 0) return byCount;
        final aIdx = recent.indexOf(display[a.key] ?? a.key);
        final bIdx = recent.indexOf(display[b.key] ?? b.key);
        return aIdx.compareTo(bIdx);
      });

    return entries.map((e) => display[e.key] ?? e.key).take(limit).toList();
  }

  /// Number of distinct topics ever searched.
  Future<int> distinctTopicsCount() async {
    final freq = await _getFrequency();
    return freq.length;
  }

  /// Total number of searches performed, counting repeats.
  Future<int> totalSearches() async {
    final freq = await _getFrequency();
    return freq.values.fold<int>(0, (sum, v) => sum + v);
  }
}