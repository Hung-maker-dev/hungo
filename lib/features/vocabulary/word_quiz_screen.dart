// lib/features/vocabulary/word_quiz_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/vocabulary_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/progress_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/database_helper.dart';

class WordQuizScreen extends StatefulWidget {
  const WordQuizScreen({super.key});
  @override
  State<WordQuizScreen> createState() => _WordQuizScreenState();
}

class _WordQuizScreenState extends State<WordQuizScreen> {
  List<Map<String, dynamic>> _questions = [];
  int _idx = 0;
  int _score = 0;
  String? _selected;
  bool _answered = false;
  bool _loading = true;
  final _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('vocabulary', limit: 100);
    if (rows.length < 4) {
      setState(() => _loading = false);
      return;
    }
    final rng = Random();
    final shuffled = [...rows]..shuffle(rng);
    final selected = shuffled.take(10).toList();

    _questions = selected.map((q) {
      final wrong = shuffled
          .where((r) => r['id'] != q['id'])
          .toList()..shuffle(rng);
      final opts = [q['definition'], ...wrong.take(3).map((r) => r['definition'])]
        ..shuffle(rng);
      return {'word': q['word'], 'correct': q['definition'], 'options': opts};
    }).toList();

    setState(() => _loading = false);
  }

  void _answer(String choice) {
    if (_answered) return;
    final correct = _questions[_idx]['correct'] as String;
    setState(() {
      _selected = choice;
      _answered = true;
      if (choice == correct) _score++;
    });
  }

  void _next() {
    if (_idx < _questions.length - 1) {
      setState(() { _idx++; _selected = null; _answered = false; });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    final auth = context.read<AuthProvider>();
    final prog = context.read<ProgressProvider>();
    final secs = DateTime.now().difference(_startTime).inSeconds;
    if (auth.isLoggedIn) {
      prog.saveProgress(
        skill: 'vocabulary',
        score: _score * 10,
        maxScore: _questions.length * 10,
        timeSpent: secs,
      );
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kết quả', textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_score / ${_questions.length}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold,
                  color: AppTheme.primary)),
          const SizedBox(height: 8),
          Text(_score >= 8 ? '🎉 Xuất sắc!' : _score >= 5 ? '👍 Tốt lắm!' : '💪 Cố lên!',
              style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text('Thời gian: ${secs}s', style: TextStyle(color: Colors.grey.shade600)),
        ]),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Thoát'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() { _idx = 0; _score = 0; _selected = null; _answered = false; });
              _loadQuestions();
            },
            child: const Text('Chơi lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trắc nghiệm')),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Chưa có đủ từ vựng để làm bài'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Quay lại')),
          ]),
        ),
      );
    }

    final q = _questions[_idx];
    final opts = q['options'] as List;
    final correct = q['correct'] as String;

    return Scaffold(
      appBar: AppBar(
        title: Text('Câu ${_idx + 1}/${_questions.length}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_idx + 1) / _questions.length,
            backgroundColor: Colors.white30,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 20),
              const SizedBox(width: 4),
              Text('$_score điểm', style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 20),

            // Question card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Column(children: [
                  const Text('Từ tiếng Anh',
                      style: TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 10),
                  Text(q['word'] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 36,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Nghĩa là gì?',
                      style: TextStyle(color: Colors.white70, fontSize: 15)),
                ]),
              ),
            ),
            const SizedBox(height: 28),
            const Text('Chọn đáp án:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 12),

            // Options
            ...opts.map((opt) {
              Color? bg, border;
              if (_answered) {
                if (opt == correct) { bg = Colors.green.shade50; border = Colors.green; }
                else if (opt == _selected) { bg = Colors.red.shade50; border = Colors.red; }
              }
              return GestureDetector(
                onTap: () => _answer(opt as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: bg ?? Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: border ?? Colors.grey.shade300,
                      width: border != null ? 2 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(opt as String,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: opt == _selected || (opt == correct && _answered)
                                ? FontWeight.w600 : FontWeight.normal))),
                    if (_answered && opt == correct)
                      const Icon(Icons.check_circle_rounded, color: Colors.green),
                    if (_answered && opt == _selected && opt != correct)
                      const Icon(Icons.cancel_rounded, color: Colors.red),
                  ]),
                ),
              );
            }),

            const Spacer(),
            if (_answered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  child: Text(_idx < _questions.length - 1 ? 'Câu tiếp theo →' : 'Xem kết quả'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
