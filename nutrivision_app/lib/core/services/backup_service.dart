import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:nutrivision_app/core/services/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  Future<void> exportData() async {
    try {
      // 1. Get data from DB
      final logs = await DatabaseHelper.instance.getAllFoodLogs();
      final data = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'food_logs': logs,
      };

      // 2. Convert to JSON
      final jsonString = jsonEncode(data);

      // 3. Save to temporary file
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/nutrivision_backup.json');
      await file.writeAsString(jsonString);

      // 4. Share file
      await SharePlus.instance.share(
        ShareParams(
          text: 'NutriVision Backup',
          files: [XFile(file.path)],
        ),
      );
    } catch (e) {
      debugPrint('Export failed: $e');
      rethrow;
    }
  }

  Future<bool> importData() async {
    try {
      // 1. Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        
        // 2. Parse JSON
        final Map<String, dynamic> data = jsonDecode(jsonString);
        
        if (data.containsKey('food_logs')) {
          final List<dynamic> logsDynamic = data['food_logs'];
          final List<Map<String, dynamic>> logs = logsDynamic.cast<Map<String, dynamic>>();

          // 3. Restore to DB
          await DatabaseHelper.instance.restoreFoodLogs(logs);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Import failed: $e');
      return false;
    }
  }
}
