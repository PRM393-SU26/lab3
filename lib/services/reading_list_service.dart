import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart' hide Source;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/work.dart';

class ReadingListService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _key {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'guest';
    return 'reading_list_$uid';
  }

  Future<List<Work>> getAll() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('bookmarks')
            .get();
        final cloudItems = snapshot.docs
            .map((doc) => _workFromJson(doc.data()))
            .toList();

        // Sync with local SharedPreferences cache
        final prefs = await SharedPreferences.getInstance();
        final encoded = jsonEncode(cloudItems.map(_workToJson).toList());
        await prefs.setString(_key, encoded);

        return cloudItems;
      } catch (e) {
        print("Firestore bookmarks fetch failed: $e");
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => _workFromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(Work work) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final cleanId = work.id.replaceFirst('https://openalex.org/', '');
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('bookmarks')
            .doc(cleanId)
            .set(_workToJson(work));
      } catch (e) {
        print("Firestore bookmark add failed: $e");
      }
    }

    final items = await getAll();
    if (items.any((w) => w.id == work.id)) return;

    items.add(work);
    await _persist(items);
  }

  Future<void> remove(String workId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final cleanId = workId.replaceFirst('https://openalex.org/', '');
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('bookmarks')
            .doc(cleanId)
            .delete();
      } catch (e) {
        print("Firestore bookmark delete failed: $e");
      }
    }

    final items = await getAll();
    items.removeWhere((w) => w.id == workId);
    await _persist(items);
  }

  Future<bool> contains(String workId) async {
    final items = await getAll();
    return items.any((w) => w.id == workId);
  }

  Future<void> _persist(List<Work> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map(_workToJson).toList());
    await prefs.setString(_key, encoded);
  }

  Map<String, dynamic> _workToJson(Work work) {
    return {
      'id': work.id,
      'title': work.title,
      'publicationYear': work.publicationYear,
      'citedByCount': work.citedByCount,
      'doi': work.doi,
      'isOpenAccess': work.isOpenAccess,
      'type': work.type,
      'primarySourceName': work.primarySource?.displayName,
      'volume': work.volume,
      'issue': work.issue,
    };
  }

  Work _workFromJson(Map<String, dynamic> json) {
    final sourceName = json['primarySourceName'] as String?;
    return Work(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      publicationYear: json['publicationYear'] as int?,
      citedByCount: json['citedByCount'] as int? ?? 0,
      doi: json['doi'] as String?,
      isOpenAccess: json['isOpenAccess'] as bool? ?? false,
      authorships: const [],
      primarySource: sourceName != null
          ? Source(displayName: sourceName)
          : null,
      type: json['type'] as String?,
      volume: json['volume'] as String?,
      issue: json['issue'] as String?,
    );
  }
}