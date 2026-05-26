// lib/core/providers/lesson_provider.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class LessonProvider extends ChangeNotifier {
  List<LessonModel> _lessons = [];
  List<QuestionModel> _questions = [];
  bool _isLoading = false;
  String _filterSkill = '';
  String _filterLevel = '';

  List<LessonModel> get lessons => _lessons;
  List<QuestionModel> get questions => _questions;
  bool get isLoading => _isLoading;

  List<LessonModel> get filtered {
    return _lessons.where((l) {
      final skillOk = _filterSkill.isEmpty || l.skill == _filterSkill;
      final levelOk = _filterLevel.isEmpty || l.level == _filterLevel;
      return skillOk && levelOk;
    }).toList();
  }

  void setFilter({String skill = '', String level = ''}) {
    _filterSkill = skill;
    _filterLevel = level;
    notifyListeners();
  }

  Future<void> loadLessons({String? skill}) async {
    _isLoading = true;
    notifyListeners();
    final db = await DatabaseHelper.instance.database;
    final where = skill != null ? 'skill = ? AND is_published = 1' : 'is_published = 1';
    final args = skill != null ? [skill] : null;
    final rows = await db.query('lessons',
        where: where, whereArgs: args, orderBy: 'created_at DESC');
    _lessons = rows.map((r) => LessonModel.fromMap(r)).toList();
    _isLoading = false;
    notifyListeners();
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
