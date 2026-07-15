import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'search_history_service.dart';
import 'item_frequency_service.dart';

/// Syncs locally-tracked user interest signals (search history, journal/keyword
/// view counts) up to Firestore so that Cloud Functions can read them for
/// notification targeting.
///
/// Called once per app session after the user authenticates.  Writes to
/// `users/{uid}/interests/{interestId}` — the same collection that
/// `evaluateAndNotify` Cloud Function queries.
class UserInterestSyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Storage keys must match the ones used in the respective screens.
  static final ItemFrequencyService _journalFreq =
      ItemFrequencyService(storageKey: 'journal_view_freq');
  static final ItemFrequencyService _keywordFreq =
      ItemFrequencyService(storageKey: 'keyword_view_freq');
  static final SearchHistoryService _searchHistory = SearchHistoryService();

  /// Signal weights used to compute a local interest score.
  static const _weights = {
    'search_count': 3.0,
    'view_count': 1.0,
    'export_count': 5.0,
    'for_you_tap_count': 2.0,
  };

  /// Syncs the user's top interests from local storage to Firestore.
  /// Safe to call multiple times — uses `set(merge: true)` to avoid
  /// overwriting fields written by Cloud Functions (e.g. server-side score).
  static Future<void> syncInterests() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userRef = _firestore.collection('users').doc(user.uid);

      // Ensure the user document exists with basic profile data.
      await userRef.set({
        'displayName': user.displayName ?? '',
        'email': user.email ?? '',
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final interestsRef = userRef.collection('interests');
      final batch = _firestore.batch();
      int batchCount = 0;

      // ── Search topics ──────────────────────────────────────────
      final topTopics = await _searchHistory.getTopTopics(limit: 10);
      final searchFreq = await _searchHistory.getAll();

      for (final topic in topTopics) {
        final normalized = topic.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
        if (normalized.isEmpty) continue;

        // Count how many times this topic appears in search history
        // (approximate — the frequency service tracks this more precisely).
        final searchCount = searchFreq.where(
          (s) => s.toLowerCase() == topic.toLowerCase(),
        ).length;

        final docRef = interestsRef.doc(_docId(normalized));
        batch.set(docRef, {
          'displayName': topic,
          'type': 'topic',
          'sourceSignals': {
            'search_count': FieldValue.increment(0), // preserve existing
          },
          'lastInteractionAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Overwrite search_count with the actual local value.
        batch.update(docRef, {
          'sourceSignals.search_count': searchCount > 0 ? searchCount : 1,
        });

        batchCount++;
        if (batchCount >= 400) {
          await batch.commit();
          batchCount = 0;
        }
      }

      // ── Journal interests ──────────────────────────────────────
      final topJournals = await _journalFreq.getTopItems(limit: 5);
      for (final item in topJournals) {
        final normalized = item.displayName.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
        if (normalized.isEmpty) continue;

        final docRef = interestsRef.doc(_docId(normalized));
        batch.set(docRef, {
          'displayName': item.displayName,
          'type': 'journal',
          'sourceSignals': {
            'view_count': item.count,
          },
          'lastInteractionAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        batchCount++;
      }

      // ── Keyword interests ─────────────────────────────────────
      final topKeywords = await _keywordFreq.getTopItems(limit: 5);
      for (final item in topKeywords) {
        final normalized = item.displayName.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
        if (normalized.isEmpty) continue;

        final docRef = interestsRef.doc(_docId(normalized));
        batch.set(docRef, {
          'displayName': item.displayName,
          'type': 'keyword',
          'sourceSignals': {
            'view_count': item.count,
          },
          'lastInteractionAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        batchCount++;
      }

      // Compute and write a local interest score for each document.
      if (batchCount > 0) {
        await batch.commit();
      }

      // Second pass: recompute scores for all interests.
      await _recomputeScores(interestsRef);
    } catch (e) {
      if (kDebugMode) {
        print('UserInterestSyncService.syncInterests failed: $e');
      }
    }
  }

  /// Recomputes the `score` field for every interest document.
  static Future<void> _recomputeScores(CollectionReference interestsRef) async {
    final snapshot = await interestsRef.get();
    if (snapshot.docs.isEmpty) return;

    // Find max raw score for normalization.
    double maxRaw = 1.0;
    final rawScores = <String, double>{};

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final signals = data['sourceSignals'] as Map<String, dynamic>? ?? {};
      double raw = 0;
      for (final entry in _weights.entries) {
        raw += (signals[entry.key] as num?)?.toDouble() ?? 0 * entry.value;
      }
      rawScores[doc.id] = raw;
      if (raw > maxRaw) maxRaw = raw;
    }

    // Normalize and apply time decay, then write back.
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final raw = rawScores[doc.id] ?? 0;
      final normalized = raw / maxRaw;

      // Time decay: interest decays over 90 days of inactivity.
      final lastInteraction = (data['lastInteractionAt'] as Timestamp?)?.toDate();
      double decay = 1.0;
      if (lastInteraction != null) {
        final daysSince = DateTime.now().difference(lastInteraction).inDays;
        decay = (1.0 - daysSince / 90).clamp(0.1, 1.0);
      }

      batch.update(doc.reference, {
        'score': double.parse((normalized * decay).toStringAsFixed(4)),
      });
    }
    await batch.commit();
  }

  /// Creates a Firestore-safe document ID from a display name.
  static String _docId(String normalized) {
    return normalized
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '')
        .substring(0, normalized.length.clamp(0, 60));
  }
}
