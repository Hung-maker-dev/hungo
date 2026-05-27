// lib/features/writing/writing_exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/lesson_provider.dart';
import '../../core/providers/progress_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class WritingExerciseScreen extends StatefulWidget {
  final dynamic lesson;
  const WritingExerciseScreen({super.key, required this.lesson});
  @override
  State<WritingExerciseScreen> createState() => _WritingExerciseScreenState();
}

class _WritingExerciseScreenState extends State<WritingExerciseScreen> {
  static const _color = Color(0xFF6A1B9A);
  final Map<int, TextEditingController> _ctrls = {};
  final Map<int, bool> _results = {};
  bool _submitted = false;
  bool _showSample = false;
  int  _score = 0;
  final _startTime = DateTime.now();

  LessonModel get _lesson => widget.lesson as LessonModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadQuestions(_lesson.id!);
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  void _submit(List<QuestionModel> questions) {
    int s = 0;
    final results = <int, bool>{};
    for (int i = 0; i < questions.length; i++) {
      final ans     = (_ctrls[i]?.text ?? '').trim().toLowerCase();
      final correct = questions[i].correctAnswer.trim().toLowerCase();
      // Writing: so sánh chứa từ khóa (linh hoạt hơn exact match)
      final ok = ans.contains(correct) || correct.contains(ans) || ans == correct;
      results[i] = ok;
      if (ok) s += questions[i].points;
    }
    setState(() { _results.addAll(results); _score = s; _submitted = true; });

    final auth    = context.read<AuthProvider>();
    final prog    = context.read<ProgressProvider>();
    final maxScore = questions.fold<int>(0, (a, q) => a + q.points);
    final secs    = DateTime.now().difference(_startTime).inSeconds;
    if (auth.isLoggedIn) {
      prog.saveProgress(skill: 'writing', lessonId: _lesson.id,
          score: s, maxScore: maxScore, timeSpent: secs);
    }

    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kết quả', textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$s / $maxScore',
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold,
                  color: _color)),
          const SizedBox(height: 8),
          Text('${results.values.where((v) => v).length}/${questions.length} câu đúng'),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('Thoát')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() { _submitted = false; _score = 0; _results.clear();
                for (final c in _ctrls.values) c.clear(); });
            },
            child: const Text('Làm lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LessonProvider>();
    final questions = lp.questions;
    for (int i = 0; i < questions.length; i++) {
      _ctrls.putIfAbsent(i, () => TextEditingController());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson.title, overflow: TextOverflow.ellipsis),
        backgroundColor: _color,
        actions: [
          if (_submitted)
            TextButton(
              onPressed: () => setState(() => _showSample = !_showSample),
              child: Text(_showSample ? 'Ẩn mẫu' : 'Xem mẫu',
                  style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: lp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Đề bài
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [_color, _color.withOpacity(0.7)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        Icon(Icons.assignment_outlined, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Đề bài', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ]),
                      const SizedBox(height: 8),
                      Text(_lesson.content ?? _lesson.description ?? 'Làm bài tập viết bên dưới',
                          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6)),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                // Câu hỏi
                if (questions.isEmpty)
                  const Center(child: Text('Chưa có câu hỏi'))
                else ...[
                  ...List.generate(questions.length, (i) {
                    final q      = questions[i];
                    final ctrl   = _ctrls[i]!;
                    final result = _results[i];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Câu ${i+1}: ${q.questionText}',
                              style: const TextStyle(fontWeight: FontWeight.w600,
                                  fontSize: 15, height: 1.5)),
                          const SizedBox(height: 12),

                          // MCQ
                          if (q.questionType == 'mcq' && q.options != null)
                            ...q.options!.map((opt) {
                              Color? bg, border;
                              if (_submitted) {
                                if (opt == q.correctAnswer) { bg = Colors.green.shade50; border = Colors.green; }
                                else if (opt == ctrl.text) { bg = Colors.red.shade50; border = Colors.red; }
                              }
                              return GestureDetector(
                                onTap: _submitted ? null
                                    : () => setState(() => ctrl.text = opt),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                  decoration: BoxDecoration(
                                    color: bg ?? (ctrl.text == opt
                                        ? _color.withOpacity(0.1) : null),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: border ?? (ctrl.text == opt ? _color : Colors.grey.shade300),
                                      width: border != null || ctrl.text == opt ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(children: [
                                    Expanded(child: Text(opt)),
                                    if (_submitted && opt == q.correctAnswer)
                                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                                  ]),
                                ),
                              );
                            }),

                          // Fill blank / viết tự do
                          if (q.questionType == 'fill_blank' || q.questionType == 'writing')
                            TextField(
                              controller: ctrl, enabled: !_submitted,
                              maxLines: q.questionType == 'writing' ? 5 : 2,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: q.questionType == 'writing'
                                    ? 'Viết câu trả lời của bạn' : 'Điền vào chỗ trống',
                                prefixIcon: const Icon(Icons.edit_outlined),
                                suffixIcon: _submitted
                                    ? Icon(result == true
                                        ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                        color: result == true ? Colors.green : Colors.red)
                                    : null,
                              ),
                            ),

                          if (_submitted && result == false) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  const Icon(Icons.check_rounded, color: Colors.green, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Đáp án: ${q.correctAnswer}',
                                      style: const TextStyle(color: Colors.green,
                                          fontWeight: FontWeight.w600)),
                                ]),
                                if (q.explanation != null) ...[
                                  const SizedBox(height: 4),
                                  Text('💡 ${q.explanation}',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                ],
                              ]),
                            ),
                          ],
                        ]),
                      ),
                    );
                  }),

                  if (!_submitted)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _ctrls.values.every((c) => c.text.isNotEmpty)
                            ? () => _submit(questions) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Nộp bài'),
                      ),
                    ),
                ],
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
