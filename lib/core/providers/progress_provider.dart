// lib/core/providers/progress_provider.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class ProgressProvider extends ChangeNotifier {
  int? _userId;
  Map<String, int> _scores = {};
  Map<String, int> _streaks = {};
  List<UserProgress> _recentProgress = [];
  bool _isLoading = false;

  Map<String, int> get scores => _scores;
  Map<String, int> get streaks => _streaks;
  List<UserProgress> get recentProgress => _recentProgress;
  bool get isLoading => _isLoading;

  int totalPoints() => _scores.values.fold(0, (a, b) => a + b);

  void onAuthChanged(int? userId) {
    _userId = userId;
    if (userId != null) loadAll();
  }

  Future<void> loadAll() async {
    if (_userId == null) return;
    _isLoading = true;
    notifyListeners();
    final db = await DatabaseHelper.instance.database;

    // Scores
    final scoreRows = await db.query('scores',
        where: 'user_id = ?', whereArgs: [_userId]);
    _scores = {for (final r in scoreRows) r['skill'] as String: r['total_pts'] as int};
    _streaks = {for (final r in scoreRows) r['skill'] as String: r['streak'] as int};

    // Recent progress
    final progRows = await db.query('user_progress',
        where: 'user_id = ?',
        whereArgs: [_userId],
        orderBy: 'created_at DESC',
        limit: 20);
    _recentProgress = progRows.map((r) => UserProgress.fromMap(r)).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveProgress({
    required String skill,
    int? lessonId,
    int? grammarId,
    required int score,
    required int maxScore,
    required int timeSpent,
  }) async {
    if (_userId == null) return;
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    await db.insert('user_progress', {
      'user_id': _userId,
      'lesson_id': lessonId,
      'grammar_id': grammarId,
      'skill': skill,
      'score': score,
      'max_score': maxScore,
      'is_completed': score >= maxScore * 0.6 ? 1 : 0,
      'time_spent': timeSpent,
      'completed_at': now,
    });

    // Cộng điểm vào bảng scores
    final existing = await db.query('scores',
        where: 'user_id = ? AND skill = ?', whereArgs: [_userId, skill]);
    if (existing.isEmpty) {
      await db.insert('scores', {
        'user_id': _userId, 'skill': skill,
        'total_pts': score, 'streak': 1, 'last_study': now,
      });
    } else {
      final cur = existing.first;
      final lastStudy = cur['last_study'] as String?;
      int streak = cur['streak'] as int? ?? 0;

      // Tính streak: nếu hôm qua có học thì +1, không thì reset về 1
      if (lastStudy != null) {
        final last = DateTime.parse(lastStudy);
        final diff = DateTime.now().difference(last).inDays;
        if (diff == 1) streak += 1;
        else if (diff > 1) streak = 1;
      } else {
        streak = 1;
      }

      await db.update('scores', {
        'total_pts': (cur['total_pts'] as int) + score,
        'streak': streak,
        'last_study': now,
        'updated_at': now,
      }, where: 'user_id = ? AND skill = ?', whereArgs: [_userId, skill]);
    }

    await loadAll();
  }
}
