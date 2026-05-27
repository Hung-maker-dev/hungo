// lib/core/providers/lesson_provider.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class LessonProvider extends ChangeNotifier {
  // Tách riêng từng skill để không bị lẫn lộn
  final Map<String, List<LessonModel>> _lessonsBySkill = {};
  List<LessonModel> _currentLessons = [];
  List<QuestionModel> _questions = [];
  bool _isLoading = false;
  String _filterLevel = '';
  String _lastLoadedSkill = '';

  List<LessonModel> get lessons => _currentLessons;
  List<QuestionModel> get questions => _questions;
  bool get isLoading => _isLoading;

  List<LessonModel> get filtered {
    return _currentLessons.where((l) =>
    _filterLevel.isEmpty || l.level == _filterLevel).toList();
  }

  void setFilter({String skill = '', String level = ''}) {
    _filterLevel = level;
    notifyListeners();
  }

  Future<void> loadLessons({String? skill}) async {
    _isLoading = true;
    if (skill != null) _lastLoadedSkill = skill;
    notifyListeners();
    final db = await DatabaseHelper.instance.database;
    final where = skill != null ? 'skill = ? AND is_published = 1' : 'is_published = 1';
    final args  = skill != null ? [skill] : null;
    final rows  = await db.query('lessons',
        where: where, whereArgs: args, orderBy: 'created_at DESC');
    final loaded = rows.map((r) => LessonModel.fromMap(r)).toList();
    if (skill != null) {
      _lessonsBySkill[skill] = loaded;
      _currentLessons = loaded;
    } else {
      _currentLessons = loaded;
    }
    _isLoading = false;
    notifyListeners();
  }

  // Lấy lessons theo skill cụ thể (dùng cache nếu có)
  List<LessonModel> getLessonsBySkill(String skill) {
    return _lessonsBySkill[skill] ?? [];
  }

  Future<void> loadQuestions(int lessonId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('questions',
        where: 'lesson_id = ?',
        whereArgs: [lessonId],
        orderBy: 'order_index ASC');
    _questions = rows.map((r) => QuestionModel.fromMap(r)).toList();
    notifyListeners();
  }

  Future<int> addLesson(LessonModel lesson) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('lessons', lesson.toMap());
    await loadLessons();
    return id;
  }

  Future<void> updateLesson(LessonModel lesson) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('lessons', lesson.toMap(),
        where: 'id = ?', whereArgs: [lesson.id]);
    await loadLessons();
  }

  Future<void> deleteLesson(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('lessons', where: 'id = ?', whereArgs: [id]);
    await loadLessons();
  }

  Future<void> addQuestion(QuestionModel q) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('questions', q.toMap());
    await loadQuestions(q.lessonId);
  }
}
