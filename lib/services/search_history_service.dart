import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const _key = 'search_history';
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
  }
}
