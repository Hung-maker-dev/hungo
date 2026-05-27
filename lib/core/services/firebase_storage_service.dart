// lib/core/services/firebase_storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class FirebaseStorageService {
  static final _storage = FirebaseStorage.instance;

  /// Cho admin chọn file mp3/wav từ thiết bị rồi upload lên Firebase
  /// Trả về download URL hoặc null nếu thất bại
  static Future<UploadResult> pickAndUploadAudio({
    required String lessonTitle,
    void Function(double progress)? onProgress,
  }) async {
    // 1. Mở file picker
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return UploadResult(cancelled: true);
    }

    final file = result.files.first;
    if (file.path == null) {
      return UploadResult(error: 'Không đọc được file');
    }

    // 2. Upload lên Firebase Storage
    try {
      final ext = file.extension ?? 'mp3';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_'
          '${lessonTitle.replaceAll(' ', '_')}.$ext';
      final ref = _storage.ref().child('audio/lessons/$fileName');

      final uploadTask = ref.putFile(
        File(file.path!),
        SettableMetadata(contentType: 'audio/$ext'),
      );

      // Theo dõi tiến trình upload
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      // Chờ upload hoàn tất
      await uploadTask;
      final url = await ref.getDownloadURL();

      return UploadResult(
        downloadUrl: url,
        fileName: file.name,
        fileSizeKb: (file.size / 1024).round(),
      );
    } on FirebaseException catch (e) {
      return UploadResult(error: 'Firebase lỗi: ${e.message}');
    } catch (e) {
      return UploadResult(error: 'Lỗi upload: $e');
    }
  }

  /// Xóa file audio khỏi Firebase Storage theo URL
  static Future<void> deleteAudio(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (_) {}
  }
}

class UploadResult {
  final String? downloadUrl;
  final String? fileName;
  final int? fileSizeKb;
  final String? error;
  final bool cancelled;

  UploadResult({
    this.downloadUrl,
    this.fileName,
    this.fileSizeKb,
    this.error,
    this.cancelled = false,
  });

  bool get isSuccess => downloadUrl != null;
}
