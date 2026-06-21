// lib/core/providers/submission_provider.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class SubmissionProvider extends ChangeNotifier {
  List<SubmissionModel> _mySubmissions   = [];
  List<SubmissionModel> _pendingList     = [];
  List<SubmissionModel> _allSubmissions  = [];
  bool _loading = false;
  int  _pendingCount = 0;

  List<SubmissionModel> get mySubmissions  => _mySubmissions;
  List<SubmissionModel> get pendingList    => _pendingList;
  List<SubmissionModel> get allSubmissions => _allSubmissions;
  bool get loading        => _loading;
  int  get pendingCount   => _pendingCount;

  // ── Học viên nộp bài ──────────────────────────────────────────────────────
  Future<int> submitAnswer({
    required int    lessonId,
    required int    questionId,
    required int    userId,
    required String answerText,
    required int    maxScore,
  }) async {
    final id = await DatabaseHelper.instance.insertSubmission({
      'lesson_id':   lessonId,
      'question_id': questionId,
      'user_id':     userId,
      'answer_text': answerText,
      'max_score':   maxScore,
      'status':      'pending',
      'submitted_at': DateTime.now().toIso8601String(),
    });
    await loadMySubmissions(userId);
    await refreshPendingCount();
    return id;
  }

  // ── Học viên xem bài của mình ────────────────────────────────────────────
  Future<void> loadMySubmissions(int userId) async {
    _loading = true; notifyListeners();
    final rows = await DatabaseHelper.instance.getSubmissionsByUser(userId);
    _mySubmissions = rows.map(SubmissionModel.fromMap).toList();
    _loading = false; notifyListeners();
  }

  Future<List<SubmissionModel>> getSubmissionsForQuestion({
    required int userId,
    required int questionId,
  }) async {
    final rows = await DatabaseHelper.instance.getSubmissionsByUserAndQuestion(
      userId: userId, questionId: questionId,
    );
    return rows.map(SubmissionModel.fromMap).toList();
  }

  // ── Admin: danh sách chờ chấm ────────────────────────────────────────────
  Future<void> loadPending() async {
    _loading = true; notifyListeners();
    final rows = await DatabaseHelper.instance.getPendingSubmissions();
    _pendingList = rows.map(SubmissionModel.fromMap).toList();
    _loading = false; notifyListeners();
  }

  Future<void> loadAll({String? status}) async {
    _loading = true; notifyListeners();
    final rows = await DatabaseHelper.instance.getAllSubmissions(status: status);
    _allSubmissions = rows.map(SubmissionModel.fromMap).toList();
    _loading = false; notifyListeners();
  }

  // ── Admin chấm bài ───────────────────────────────────────────────────────
  Future<void> gradeSubmission({
    required int    submissionId,
    required int    score,
    required int    maxScore,
    String?         feedback,
    // để cập nhật leaderboard sau khi chấm
    required int    userId,
    required int    lessonId,
    required String skill,
    required int    timeSpent,
  }) async {
    await DatabaseHelper.instance.gradeSubmission(
      submissionId: submissionId,
      score:        score,
      maxScore:     maxScore,
      feedback:     feedback,
    );

    // Cập nhật user_progress (giống saveProgress trong ProgressProvider)
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query('user_progress',
        where: 'user_id = ? AND lesson_id = ?',
        whereArgs: [userId, lessonId]);
    if (existing.isEmpty) {
      await db.insert('user_progress', {
        'user_id':      userId,
        'lesson_id':    lessonId,
        'skill':        skill,
        'score':        score,
        'max_score':    maxScore,
        'is_completed': 1,
        'time_spent':   timeSpent,
        'attempts':     1,
        'completed_at': DateTime.now().toIso8601String(),
      });
    } else {
      final prev = existing.first['score'] as int? ?? 0;
      if (score > prev) {
        await db.update('user_progress',
            {'score': score, 'max_score': maxScore,
              'is_completed': 1, 'completed_at': DateTime.now().toIso8601String()},
            where: 'user_id = ? AND lesson_id = ?',
            whereArgs: [userId, lessonId]);
      }
      await db.rawUpdate(
          'UPDATE user_progress SET attempts = attempts + 1 '
              'WHERE user_id = ? AND lesson_id = ?',
          [userId, lessonId]);
    }

    await loadPending();
    await refreshPendingCount();
  }

  Future<void> refreshPendingCount() async {
    _pendingCount = await DatabaseHelper.instance.countPendingSubmissions();
    notifyListeners();
  }
}