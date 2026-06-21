// lib/core/providers/lesson_provider.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class LessonProvider extends ChangeNotifier {
  // Tách riêng từng skill để KHÔNG bị lẫn lộn
  final Map<String, List<LessonModel>> _bySkill = {
    'reading': [], 'listening': [], 'grammar': [], 'writing': [],
  };
  List<QuestionModel> _questions = [];
  bool _isLoading = false;
  bool _initialLoaded = false;

  List<QuestionModel> get questions => _questions;
  bool get isLoading => _isLoading;
  bool get initialLoaded => _initialLoaded;

  List<LessonModel> getBySkill(String skill) => List.unmodifiable(_bySkill[skill] ?? []);

  // ── Load tất cả skill khi khởi động app ────────────────────────────────────
  Future<void> loadAll() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('lessons',
          where: 'is_published = 1', orderBy: 'created_at DESC');
      for (final skill in _bySkill.keys) {
        _bySkill[skill] = rows
            .where((r) => r['skill'] == skill)
            .map((r) => LessonModel.fromMap(r))
            .toList();
      }
      _initialLoaded = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Load tất cả (kể cả unpublished) dành cho admin ────────────────────────
  Future<void> loadAllForAdmin() async {
    _isLoading = true;
    notifyListeners();
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('lessons', orderBy: 'created_at DESC');
      for (final skill in _bySkill.keys) {
        _bySkill[skill] = rows
            .where((r) => r['skill'] == skill)
            .map((r) => LessonModel.fromMap(r))
            .toList();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<QuestionModel>> loadQuestions(int lessonId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('questions',
        where: 'lesson_id = ?', whereArgs: [lessonId],
        orderBy: 'order_index ASC');
    _questions = rows.map((r) => QuestionModel.fromMap(r)).toList();
    notifyListeners();
    return _questions;
  }

  Future<int> addLesson(LessonModel lesson) async {
    final db = await DatabaseHelper.instance.database;
    final id = await db.insert('lessons', lesson.toMap());
    await loadAll();
    return id;
  }

  Future<void> updateLesson(LessonModel lesson) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('lessons', lesson.toMap(),
        where: 'id = ?', whereArgs: [lesson.id]);
    await loadAll();
  }

  Future<void> deleteLesson(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('lessons', where: 'id = ?', whereArgs: [id]);
    await loadAll();
  }

  Future<void> deleteQuestionsForLesson(int lessonId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('questions', where: 'lesson_id = ?', whereArgs: [lessonId]);
  }

  Future<void> addQuestion(QuestionModel q) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('questions', q.toMap());
  }

  Future<void> updateQuestion(QuestionModel q) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('questions', q.toMap(),
        where: 'id = ?', whereArgs: [q.id]);
  }

  LessonModel? getGrammarLessonByTopic(String topicName) {
    final list = _bySkill['grammar'] ?? [];
    for (final l in list) {
      if (l.topic == topicName) return l;
    }
    return null;
  }
}
