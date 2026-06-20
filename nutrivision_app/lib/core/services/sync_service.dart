import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  final DatabaseService _db = DatabaseService();
  bool _isSyncing = false;

  factory SyncService() => _instance;

  SyncService._internal();

  // Initialize Supabase (Call this in main.dart)
  Future<void> init(String url, String anonKey) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
    // Start background sync listener or periodic timer
    // For now, we'll trigger sync manually or on app start/resume
  }

  // Add operation to sync queue
  Future<void> addToQueue(String table, String action, int rowId, Map<String, dynamic> payload) async {
    await _db.insert('sync_queue', {
      'table_name': table,
      'action': action,
      'row_id': rowId,
      'payload': jsonEncode(payload),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Trigger sync immediately if online
    syncPendingItems();
  }

  // Process sync queue
  Future<void> syncPendingItems() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pending = await _db.query('sync_queue', orderBy: 'timestamp ASC');
      if (pending.isEmpty) {
        _isSyncing = false;
        return;
      }

      final supabase = Supabase.instance.client;

      for (var item in pending) {
        final id = item['id'] as int;
        final table = item['table_name'] as String;
        final action = item['action'] as String;
        final payload = jsonDecode(item['payload'] as String) as Map<String, dynamic>;

        try {
          if (action == 'INSERT') {
            await supabase.from(table).insert(payload);
          } else if (action == 'UPDATE') {
            // Assuming payload has 'id' or we use row_id if it matches remote id
            // This part needs careful mapping between local ID and remote ID
            // For MVP, simple insert-only or replace might be easier
             await supabase.from(table).upsert(payload);
          } else if (action == 'DELETE') {
             await supabase.from(table).delete().match({'id': item['row_id']});
          }

          // If successful, remove from queue
          await _db.delete('sync_queue', 'id = ?', [id]);
        } catch (e) {
          debugPrint('Sync failed for item $id: $e');
          // Keep in queue to retry later
          // Optionally implement backoff or max retries
        }
      }
    } catch (e) {
      debugPrint('Sync Loop Error: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
