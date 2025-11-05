import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/collection_history.dart';

class CollectionHistoryService {
  CollectionHistoryService(this._prefs);

  static const String _storageKey = 'collection_history_records';

  final SharedPreferences _prefs;
  final ValueNotifier<List<CollectionHistoryEntry>> entriesNotifier =
      ValueNotifier<List<CollectionHistoryEntry>>(<CollectionHistoryEntry>[]);

  Future<void> initialize() async {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      entriesNotifier.value = <CollectionHistoryEntry>[];
      return;
    }
    try {
      final decoded = CollectionHistoryEntry.decodeList(raw);
      entriesNotifier.value = decoded;
    } catch (_) {
      entriesNotifier.value = <CollectionHistoryEntry>[];
    }
  }

  List<CollectionHistoryEntry> get entries =>
      List.unmodifiable(entriesNotifier.value);

  Future<void> addEntry(CollectionHistoryEntry entry) async {
    final updated = List<CollectionHistoryEntry>.from(entriesNotifier.value)
      ..add(entry);
    entriesNotifier.value = updated;
    await _persist(updated);
  }

  Future<void> clear() async {
    entriesNotifier.value = <CollectionHistoryEntry>[];
    await _prefs.remove(_storageKey);
  }

  Future<void> _persist(List<CollectionHistoryEntry> entries) async {
    final encoded = CollectionHistoryEntry.encodeList(entries);
    await _prefs.setString(_storageKey, encoded);
  }
}
