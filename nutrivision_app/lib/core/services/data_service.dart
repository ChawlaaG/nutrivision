import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_service.dart';

class DataService {
  final DatabaseService _db = DatabaseService();

  Future<void> exportData() async {
    final List<List<dynamic>> rows = [];
    rows.add(['Date', 'Type', 'Name', 'Calories', 'Amount', 'Unit']); // Header

    // 1. Fetch Meals
    final meals = await _db.query('meals');
    for (var meal in meals) {
      final date = DateTime.fromMillisecondsSinceEpoch(meal['timestamp'] as int);
      rows.add([
        date.toIso8601String(),
        'Meal',
        meal['name'],
        meal['calories'],
        1, // Default amount for now
        'serving'
      ]);
    }

    // 2. Fetch Water
    final waterLogs = await _db.query('water_logs');
    for (var log in waterLogs) {
      rows.add([
        log['date'],
        'Water',
        'Water',
        0,
        log['amount_ml'],
        'ml'
      ]);
    }

    // 3. Fetch Weight
    final weightLogs = await _db.query('weight_logs');
    for (var log in weightLogs) {
      rows.add([
        log['date'],
        'Weight',
        'Weight',
        0,
        log['weight_kg'],
        'kg'
      ]);
    }

    // 4. Generate CSV
    String csv = const ListToCsvConverter().convert(rows);

    // 5. Save to Temp File
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/nutrivision_data.csv');
    await file.writeAsString(csv);

    // 6. Share
    await SharePlus.instance.share(
      ShareParams(
        text: 'My NutriVision Data',
        files: [XFile(file.path)],
      ),
    );
  }

  Future<bool> importData() async {
    try {
      // 1. Pick File
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        final input = await file.readAsString();
        final fields = const CsvToListConverter().convert(input);

        // 2. Parse & Insert (Skip Header)
        for (var i = 1; i < fields.length; i++) {
          final row = fields[i];
          final type = row[1].toString();

          if (type == 'Meal') {
            // Re-importing meals is complex due to ID conflicts, skipping for MVP safety
            // or we could add as new entries. For now, let's focus on simple logs.
            // A robust import needs a dedicated strategy.
            // For this MVP, we will just log that we found it.
            debugPrint('Skipping meal import for safety: ${row[2]}');
          } else if (type == 'Water') {
            await _db.insert('water_logs', {
              'date': row[0],
              'amount_ml': row[4],
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
          } else if (type == 'Weight') {
             await _db.insert('weight_logs', {
              'date': row[0],
              'weight_kg': row[4],
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Import Error: $e');
      return false;
    }
  }
}
