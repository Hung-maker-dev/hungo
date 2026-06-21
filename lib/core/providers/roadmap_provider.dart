// lib/core/providers/roadmap_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class RoadmapModel {
  final int? id;
  final int userId;
  final String goal;
  final String? targetScore;
  final String levelStart;
  final int durationWeeks;
  final int dailyMinutes;
  final List<String> focusSkills;
  final String status;
  final String startDate;
  final String endDate;

  RoadmapModel({
    this.id, required this.userId, required this.goal,
    this.targetScore, this.levelStart = 'A1',
    required this.durationWeeks, this.dailyMinutes = 30,
    this.focusSkills = const ['vocabulary','grammar','reading','listening'],
    this.status = 'active',
    required this.startDate, required this.endDate,
  });

  factory RoadmapModel.fromMap(Map<String, dynamic> m) => RoadmapModel(
    id: m['id'], userId: m['user_id'], goal: m['goal'],
    targetScore: m['target_score'], levelStart: m['level_start'] ?? 'A1',
    durationWeeks: m['duration_weeks'], dailyMinutes: m['daily_minutes'] ?? 30,
    focusSkills: m['focus_skills'] == 'all'
        ? ['vocabulary','grammar','reading','listening']
        : List<String>.from(jsonDecode(m['focus_skills'] ?? '[]')),
    status: m['status'] ?? 'active',
    startDate: m['start_date'], endDate: m['end_date'],
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId, 'goal': goal, 'target_score': targetScore,
    'level_start': levelStart, 'duration_weeks': durationWeeks,
    'daily_minutes': dailyMinutes,
    'focus_skills': jsonEncode(focusSkills),
    'status': status, 'start_date': startDate, 'end_date': endDate,
  };

  int get totalDays => durationWeeks * 7;
  DateTime get start => DateTime.parse(startDate);
  DateTime get end => DateTime.parse(endDate);
  int get daysPassed => DateTime.now().difference(start).inDays.clamp(0, totalDays);
  double get overallProgress => totalDays > 0 ? daysPassed / totalDays : 0;
  bool get isCompleted => status == 'completed' || DateTime.now().isAfter(end);
  int get daysLeft => end.difference(DateTime.now()).inDays.clamp(0, totalDays);
}

class DailyTask {
  final int? id;
  final int roadmapId;
  final int userId;
  final String taskDate;
  final String skill;
  final String taskType;
  final String taskLabel;
  final int targetCount;
  int doneCount;
  bool isCompleted;

  DailyTask({
    this.id, required this.roadmapId, required this.userId,
    required this.taskDate, required this.skill,
    required this.taskType, required this.taskLabel,
    this.targetCount = 1, this.doneCount = 0, this.isCompleted = false,
  });

  factory DailyTask.fromMap(Map<String, dynamic> m) => DailyTask(
    id: m['id'], roadmapId: m['roadmap_id'], userId: m['user_id'],
    taskDate: m['task_date'], skill: m['skill'], taskType: m['task_type'],
    taskLabel: m['task_label'], targetCount: m['target_count'] ?? 1,
    doneCount: m['done_count'] ?? 0, isCompleted: (m['is_completed'] ?? 0) == 1,
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'roadmap_id': roadmapId, 'user_id': userId, 'task_date': taskDate,
    'skill': skill, 'task_type': taskType, 'task_label': taskLabel,
    'target_count': targetCount, 'done_count': doneCount,
    'is_completed': isCompleted ? 1 : 0,
  };

  double get progress => targetCount > 0 ? (doneCount / targetCount).clamp(0, 1) : 0;
}

class DailyStat {
  final String date;
  final int tasksTotal;
  final int tasksDone;
  final int wordsLearned;
  final int minutesSpent;
  final int scoreEarned;

  DailyStat({required this.date, this.tasksTotal = 0, this.tasksDone = 0,
      this.wordsLearned = 0, this.minutesSpent = 0, this.scoreEarned = 0});

  factory DailyStat.fromMap(Map<String, dynamic> m) => DailyStat(
    date: m['stat_date'], tasksTotal: m['tasks_total'] ?? 0,
    tasksDone: m['tasks_done'] ?? 0, wordsLearned: m['words_learned'] ?? 0,
    minutesSpent: m['minutes_spent'] ?? 0, scoreEarned: m['score_earned'] ?? 0,
  );

  double get completionRate => tasksTotal > 0 ? tasksDone / tasksTotal : 0;
}

// ── Provider ──────────────────────────────────────────────────────────────────

class RoadmapProvider extends ChangeNotifier {
  RoadmapModel? _activeRoadmap;
  List<DailyTask> _todayTasks = [];
  List<DailyStat> _stats = [];
  bool _isLoading = false;

  RoadmapModel? get activeRoadmap => _activeRoadmap;
  List<DailyTask> get todayTasks => _todayTasks;
  List<DailyStat> get stats => _stats;
  bool get isLoading => _isLoading;
  bool get hasRoadmap => _activeRoadmap != null;

  int get todayDone => _todayTasks.where((t) => t.isCompleted).length;
  int get todayTotal => _todayTasks.length;
  double get todayProgress => todayTotal > 0 ? todayDone / todayTotal : 0;

  // Thống kê tổng
  int get totalDaysStudied => _stats.where((s) => s.tasksDone > 0).length;
  int get totalWordsLearned => _stats.fold(0, (a, s) => a + s.wordsLearned);
  int get totalMinutes => _stats.fold(0, (a, s) => a + s.minutesSpent);
  double get avgCompletionRate => _stats.isEmpty ? 0 :
      _stats.fold(0.0, (a, s) => a + s.completionRate) / _stats.length;

  // Streak hiện tại
  int get currentStreak {
    if (_stats.isEmpty) return 0;
    int streak = 0;
    final sorted = [..._stats]..sort((a, b) => b.date.compareTo(a.date));
    DateTime check = DateTime.now();
    for (final s in sorted) {
      final d = DateTime.parse(s.date);
      final diff = check.difference(d).inDays;
      if (diff <= 1 && s.tasksDone > 0) { streak++; check = d; }
      else break;
    }
    return streak;
  }

  // ── Load lộ trình active ───────────────────────────────────────────────────
  Future<void> loadActiveRoadmap(int userId) async {
    _isLoading = true;
    notifyListeners();
    await _ensureTables();
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('roadmaps',
        where: 'user_id = ? AND status = ?',
        whereArgs: [userId, 'active'],
        orderBy: 'created_at DESC', limit: 1);
    _activeRoadmap = rows.isNotEmpty ? RoadmapModel.fromMap(rows.first) : null;
    if (_activeRoadmap != null) {
      await _generateTodayTasksIfNeeded(userId);
      await loadTodayTasks(userId);
      await loadStats(userId);
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Tạo lộ trình mới ──────────────────────────────────────────────────────
  Future<void> createRoadmap({
    required int userId,
    required String goal,
    String? targetScore,
    required String levelStart,
    required int durationWeeks,
    required int dailyMinutes,
    required List<String> focusSkills,
  }) async {
    await _ensureTables();
    final db = await DatabaseHelper.instance.database;

    // Pause lộ trình cũ nếu có
    await db.update('roadmaps', {'status': 'paused'},
        where: 'user_id = ? AND status = ?', whereArgs: [userId, 'active']);

    final now = DateTime.now();
    final end = now.add(Duration(days: durationWeeks * 7));

    final roadmap = RoadmapModel(
      userId: userId, goal: goal, targetScore: targetScore,
      levelStart: levelStart, durationWeeks: durationWeeks,
      dailyMinutes: dailyMinutes, focusSkills: focusSkills,
      startDate: _dateStr(now), endDate: _dateStr(end),
    );

    final id = await db.insert('roadmaps', roadmap.toMap());
    _activeRoadmap = RoadmapModel.fromMap({...roadmap.toMap(), 'id': id});

    // Tạo nhiệm vụ ngày đầu tiên
    await _generateTodayTasksIfNeeded(userId);
    await loadTodayTasks(userId);
    notifyListeners();
  }

  // ── Generate nhiệm vụ hôm nay ─────────────────────────────────────────────
  Future<void> _generateTodayTasksIfNeeded(int userId) async {
    if (_activeRoadmap == null) return;
    final db = await DatabaseHelper.instance.database;
    final today = _dateStr(DateTime.now());

    final existing = await db.query('daily_tasks',
        where: 'roadmap_id = ? AND task_date = ?',
        whereArgs: [_activeRoadmap!.id, today]);
    if (existing.isNotEmpty) return; // Đã tạo rồi

    // Tạo nhiệm vụ dựa theo goal + focusSkills
    final tasks = _buildTasksForGoal(
      roadmapId: _activeRoadmap!.id!,
      userId: userId,
      today: today,
      goal: _activeRoadmap!.goal,
      focusSkills: _activeRoadmap!.focusSkills,
      dailyMinutes: _activeRoadmap!.dailyMinutes,
      weekNumber: (_activeRoadmap!.daysPassed ~/ 7) + 1,
    );

    for (final t in tasks) {
      await db.insert('daily_tasks', t.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Tạo daily_stats trống
    await db.insert('daily_stats', {
      'user_id': userId, 'roadmap_id': _activeRoadmap!.id,
      'stat_date': today, 'tasks_total': tasks.length,
      'tasks_done': 0, 'words_learned': 0, 'minutes_spent': 0, 'score_earned': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // ── Sinh nhiệm vụ theo goal ───────────────────────────────────────────────
  List<DailyTask> _buildTasksForGoal({
    required int roadmapId, required int userId, required String today,
    required String goal, required List<String> focusSkills,
    required int dailyMinutes, required int weekNumber,
  }) {
    final tasks = <DailyTask>[];
    // Số từ tăng dần theo tuần
    final wordTarget = (weekNumber <= 2) ? 5 : (weekNumber <= 6) ? 10 : 15;

    DailyTask task(String skill, String type, String label, {int target = 1}) =>
        DailyTask(roadmapId: roadmapId, userId: userId, taskDate: today,
            skill: skill, taskType: type, taskLabel: label, targetCount: target);

    // Từ vựng: luôn có
    if (focusSkills.contains('vocabulary')) {
      tasks.add(task('vocabulary', 'learn_words', 'Học $wordTarget từ mới', target: wordTarget));
      tasks.add(task('vocabulary', 'flashcard', 'Ôn flashcard ($wordTarget thẻ)', target: wordTarget));
      if (weekNumber >= 2) {
        tasks.add(task('vocabulary', 'quiz', 'Trắc nghiệm từ vựng', target: 1));
      }
    }

    // Ngữ pháp
    if (focusSkills.contains('grammar')) {
      final dayOfWeek = DateTime.now().weekday;
      if (dayOfWeek <= 3) {
        // Thứ 2-4: học lý thuyết
        tasks.add(task('grammar', 'grammar_theory', 'Đọc lý thuyết ngữ pháp'));
      } else {
        // Thứ 5-CN: làm bài tập
        tasks.add(task('grammar', 'grammar_exercise', 'Làm bài tập ngữ pháp', target: 5));
      }
    }

    // Đọc
    if (focusSkills.contains('reading')) {
      final readingDays = goal == 'ielts' ? [1,2,3,4,5,6,7] : [2,4,6]; // IELTS đọc mỗi ngày
      if (readingDays.contains(DateTime.now().weekday)) {
        tasks.add(task('reading', 'reading', 'Đọc hiểu bài văn'));
      }
    }

    // Nghe
    if (focusSkills.contains('listening')) {
      final listeningDays = goal == 'ielts' ? [1,2,3,4,5,6,7] : [3,5,7];
      if (listeningDays.contains(DateTime.now().weekday)) {
        tasks.add(task('listening', 'listening', 'Luyện nghe điền từ'));
      }
    }

    // Bonus task theo goal
    if (goal == 'ielts' && weekNumber >= 3) {
      tasks.add(task('grammar', 'grammar_exercise', 'Luyện câu phức (IELTS)', target: 3));
    }
    if (goal == 'toeic' && weekNumber >= 2) {
      tasks.add(task('vocabulary', 'learn_words', 'Từ vựng TOEIC chuyên ngành', target: 5));
    }

    return tasks;
  }

  // ── Load nhiệm vụ hôm nay ─────────────────────────────────────────────────
  Future<void> loadTodayTasks(int userId) async {
    if (_activeRoadmap == null) return;
    final db = await DatabaseHelper.instance.database;
    final today = _dateStr(DateTime.now());
    final rows = await db.query('daily_tasks',
        where: 'roadmap_id = ? AND task_date = ?',
        whereArgs: [_activeRoadmap!.id, today],
        orderBy: 'skill ASC');
    _todayTasks = rows.map((r) => DailyTask.fromMap(r)).toList();
    notifyListeners();
  }

  // ── Đánh dấu task hoàn thành ──────────────────────────────────────────────
  Future<void> completeTask(DailyTask task, {int doneCount = 1}) async {
    final db = await DatabaseHelper.instance.database;
    final newDone = (task.doneCount + doneCount).clamp(0, task.targetCount);
    final completed = newDone >= task.targetCount;

    await db.update('daily_tasks', {
      'done_count': newDone,
      'is_completed': completed ? 1 : 0,
      'completed_at': completed ? DateTime.now().toIso8601String() : null,
    }, where: 'id = ?', whereArgs: [task.id]);

    // Cập nhật daily_stats
    final today = _dateStr(DateTime.now());
    final stats = await db.query('daily_stats',
        where: 'roadmap_id = ? AND stat_date = ?',
        whereArgs: [_activeRoadmap!.id, today]);

    if (stats.isNotEmpty) {
      final cur = stats.first;
      final doneTasks = (cur['tasks_done'] as int) + (completed && !task.isCompleted ? 1 : 0);
      final words = (cur['words_learned'] as int) +
          (task.taskType == 'learn_words' ? doneCount : 0);
      await db.update('daily_stats', {
        'tasks_done': doneTasks,
        'words_learned': words,
        'minutes_spent': (cur['minutes_spent'] as int) + 5,
        'score_earned': (cur['score_earned'] as int) + (completed ? 10 : 0),
      }, where: 'roadmap_id = ? AND stat_date = ?',
          whereArgs: [_activeRoadmap!.id, today]);
    }

    // Cập nhật local state
    final idx = _todayTasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      _todayTasks[idx].doneCount = newDone;
      _todayTasks[idx].isCompleted = completed;
    }
    notifyListeners();
  }

  // ── Load thống kê ─────────────────────────────────────────────────────────
  Future<void> loadStats(int userId) async {
    if (_activeRoadmap == null) return;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('daily_stats',
        where: 'roadmap_id = ?',
        whereArgs: [_activeRoadmap!.id],
        orderBy: 'stat_date ASC');
    _stats = rows.map((r) => DailyStat.fromMap(r)).toList();
    notifyListeners();
  }

  // ── Đảm bảo bảng tồn tại ─────────────────────────────────────────────────
  Future<void> _ensureTables() async {
    final db = await DatabaseHelper.instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS roadmaps (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL, goal TEXT NOT NULL,
        target_score TEXT, level_start TEXT DEFAULT 'A1',
        duration_weeks INTEGER NOT NULL, daily_minutes INTEGER DEFAULT 30,
        focus_skills TEXT DEFAULT 'all', status TEXT DEFAULT 'active',
        start_date TEXT NOT NULL, end_date TEXT NOT NULL,
        created_at TEXT DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        roadmap_id INTEGER NOT NULL, user_id INTEGER NOT NULL,
        task_date TEXT NOT NULL, skill TEXT NOT NULL,
        task_type TEXT NOT NULL, task_label TEXT NOT NULL,
        target_count INTEGER DEFAULT 1, done_count INTEGER DEFAULT 0,
        is_completed INTEGER DEFAULT 0, completed_at TEXT,
        UNIQUE(roadmap_id, task_date, skill, task_type)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL, roadmap_id INTEGER,
        stat_date TEXT NOT NULL, tasks_total INTEGER DEFAULT 0,
        tasks_done INTEGER DEFAULT 0, words_learned INTEGER DEFAULT 0,
        minutes_spent INTEGER DEFAULT 0, score_earned INTEGER DEFAULT 0,
        UNIQUE(user_id, roadmap_id, stat_date)
      )
    ''');
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  // Gợi ý số tuần theo goal
  static int suggestWeeks(String goal, String targetScore) {
    if (goal == 'ielts') {
      final score = double.tryParse(targetScore) ?? 5.0;
      if (score >= 7.0) return 16;
      if (score >= 6.0) return 12;
      return 8;
    }
    if (goal == 'toeic') {
      final score = int.tryParse(targetScore) ?? 500;
      if (score >= 800) return 16;
      if (score >= 600) return 12;
      return 8;
    }
    if (goal == 'business') return 12;
    if (goal == 'vstep') {
      // B1->B2: 12 tuần, B2->C1: 20 tuần
      if (targetScore == 'C1') return 20;
      if (targetScore == 'B2') return 12;
      return 8; // B1
    }
    return 8; // communication
  }
  // ── Load tất cả lộ trình (kể cả paused/completed) ─────────────────────────
  List<RoadmapModel> _allRoadmaps = [];
  List<RoadmapModel> get allRoadmaps => _allRoadmaps;

  Future<void> loadAllRoadmaps(int userId) async {
    await _ensureTables();
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('roadmaps',
        where: 'user_id = ?', whereArgs: [userId],
        orderBy: 'created_at DESC');
    _allRoadmaps = rows.map((r) => RoadmapModel.fromMap(r)).toList();
    notifyListeners();
  }

  Future<void> switchToRoadmap(int roadmapId, int userId) async {
    await _ensureTables();
    final db = await DatabaseHelper.instance.database;
    await db.update('roadmaps', {'status': 'paused'},
        where: 'user_id = ?', whereArgs: [userId]);
    await db.update('roadmaps', {'status': 'active'},
        where: 'id = ?', whereArgs: [roadmapId]);
    await loadActiveRoadmap(userId);
    await loadAllRoadmaps(userId);
  }

  Future<void> deleteRoadmap(int roadmapId, int userId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('roadmaps', where: 'id = ?', whereArgs: [roadmapId]);
    if (_activeRoadmap?.id == roadmapId) {
      _activeRoadmap = null;
      _todayTasks = [];
    }
    await loadAllRoadmaps(userId);
    notifyListeners();
  }

}
