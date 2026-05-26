// lib/core/providers/grammar_provider.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class GrammarProvider extends ChangeNotifier {
  List<GrammarTopic> _topics = [];
  List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = false;

  List<GrammarTopic> get topics => _topics;
  List<Map<String, dynamic>> get exercises => _exercises;
  bool get isLoading => _isLoading;

  List<GrammarTopic> byCategory(String cat) =>
      _topics.where((t) => t.category == cat).toList();

  Future<void> loadTopics() async {
    _isLoading = true;
    notifyListeners();
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('grammar_topics', orderBy: 'order_index ASC');
    _topics = rows.map((r) => GrammarTopic.fromMap(r)).toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadExercises(int grammarId) async {
    _isLoading = true;
    notifyListeners();
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'grammar_exercises',
      where: 'grammar_id = ?',
      whereArgs: [grammarId],
      orderBy: 'difficulty ASC',
    );
    _exercises = rows;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExercise(Map<String, dynamic> data) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('grammar_exercises', data);
    if (_exercises.isNotEmpty &&
        _exercises.first['grammar_id'] == data['grammar_id']) {
      await loadExercises(data['grammar_id'] as int);
    }
  }
}
