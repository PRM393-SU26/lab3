import 'package:flutter/foundation.dart';

import '../models/work.dart';
import '../services/reading_list_service.dart';

class ReadingListProvider extends ChangeNotifier {
  final ReadingListService _service = ReadingListService();

  List<Work> _items = [];
  bool _isLoaded = false;

  List<Work> get items => _items;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _items = await _service.getAll();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> toggle(Work work) async {
    if (contains(work.id)) {
      await _service.remove(work.id);
      _items.removeWhere((w) => w.id == work.id);
    } else {
      await _service.add(work);
      _items.add(work);
    }
    notifyListeners();
  }

  Future<void> remove(String workId) async {
    await _service.remove(workId);
    _items.removeWhere((w) => w.id == workId);
    notifyListeners();
  }

  bool contains(String workId) => _items.any((w) => w.id == workId);
}
