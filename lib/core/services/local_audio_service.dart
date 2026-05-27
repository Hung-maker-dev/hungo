// lib/core/services/local_audio_service.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class LocalAudioService {
  /// Cho admin chọn file mp3 từ sdcard
  /// Copy vào bộ nhớ nội bộ app → trả về đường dẫn tuyệt đối
  static Future<LocalAudioResult> pickAndCopyAudio() async {
    // 1. Mở file picker
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return LocalAudioResult(cancelled: true);
    }

    final file = result.files.first;
    if (file.path == null) {
      return LocalAudioResult(error: 'Không đọc được file');
    }

    try {
      // 2. Lấy thư mục nội bộ của app
      final appDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory(p.join(appDir.path, 'audio'));
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      // 3. Copy file vào app storage
      final fileName = p.basename(file.path!);
      final destPath = p.join(audioDir.path, fileName);
      await File(file.path!).copy(destPath);

      return LocalAudioResult(
        localPath: destPath,
        fileName: fileName,
        fileSizeKb: (file.size / 1024).round(),
      );
    } catch (e) {
      return LocalAudioResult(error: 'Lỗi copy file: $e');
    }
  }

  /// Xóa file audio khỏi bộ nhớ nội bộ
  static Future<void> deleteAudio(String localPath) async {
    try {
      final f = File(localPath);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// Kiểm tra file còn tồn tại không
  static Future<bool> exists(String localPath) async {
    return File(localPath).exists();
  }
}

class LocalAudioResult {
  final String? localPath;   // đường dẫn tuyệt đối trong app
  final String? fileName;
  final int?    fileSizeKb;
  final String? error;
  final bool    cancelled;

  LocalAudioResult({
    this.localPath, this.fileName, this.fileSizeKb,
    this.error, this.cancelled = false,
  });

  bool get isSuccess => localPath != null;
}
