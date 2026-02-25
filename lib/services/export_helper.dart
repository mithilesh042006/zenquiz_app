import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_theme.dart';

/// Handles exporting files to local storage or via share sheet.
class ExportHelper {
  /// Shows a bottom sheet letting the user choose between saving to phone
  /// storage (using the native file picker) or sharing via the system share sheet.
  static Future<void> exportFile({
    required BuildContext context,
    required String content,
    required String fileName,
    required String shareSubject,
  }) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.textDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Export File',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.white,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.save_rounded, color: AppTheme.gold),
              ),
              title: const Text(
                'Save to Phone',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Choose where to save on your device',
                style: TextStyle(fontSize: 12, color: AppTheme.textDim),
              ),
              onTap: () => Navigator.pop(ctx, 'save'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.share_rounded,
                  color: AppTheme.textMuted,
                ),
              ),
              title: const Text(
                'Share',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Share via other apps',
                style: TextStyle(fontSize: 12, color: AppTheme.textDim),
              ),
              onTap: () => Navigator.pop(ctx, 'share'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !context.mounted) return;

    try {
      if (choice == 'save') {
        await _saveToDevice(context, content, fileName);
      } else {
        await _shareFile(content, fileName, shareSubject);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  /// Uses the native system file picker (SAF) so the user can choose
  /// exactly where to save. Works on all Android versions without
  /// any storage permissions.
  static Future<void> _saveToDevice(
    BuildContext context,
    String content,
    String fileName,
  ) async {
    // Determine the file extension for the allowed extensions filter
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'csv';

    // On Android/iOS, saveFile requires bytes to write directly
    final bytes = utf8.encode(content);

    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Save $fileName',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: [ext],
      bytes: Uint8List.fromList(bytes),
    );

    if (outputPath == null) return; // user cancelled

    if (context.mounted) {
      final savedName = outputPath.split(Platform.pathSeparator).last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.correct,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Saved: $savedName',
                  style: const TextStyle(color: AppTheme.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.surface,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static Future<void> _shareFile(
    String content,
    String fileName,
    String subject,
  ) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);

    await Share.shareXFiles([XFile(file.path)], subject: subject);
  }
}
