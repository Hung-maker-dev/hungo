// lib/features/listening/listening_exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/providers/lesson_provider.dart';
import '../../core/providers/progress_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class ListeningExerciseScreen extends StatefulWidget {
  final dynamic lesson;
  const ListeningExerciseScreen({super.key, required this.lesson});
  @override
  State<ListeningExerciseScreen> createState() => _ListeningExerciseScreenState();
}

class _ListeningExerciseScreenState extends State<ListeningExerciseScreen> {
  final _tts = FlutterTts();
  bool _isPlaying = false;
  bool _hasListened = false;
  int _playCount = 0;
  final Map<int, TextEditingController> _ctrls = {};
  final Map<int, bool> _results = {};
  bool _submitted = false;
  int _score = 0;
  final _startTime = DateTime.now();

  LessonModel get _lesson => widget.lesson as LessonModel;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.42);
    _tts.setPitch(1.0);
    _tts.setCompletionHandler(() => setState(() => _isPlaying = false));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadQuestions(_lesson.id!);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    if (_isPlaying) {
      await _tts.stop();
      setState(() => _isPlaying = false);
      return;
    }
    final text = _lesson.content ?? _lesson.title;
    setState(() { _isPlaying = true; _hasListened = true; _playCount++; });
    await _tts.speak(text);
  }

  void _submit(List<QuestionModel> questions) {
    int s = 0;
    final results = <int, bool>{};
    for (int i = 0; i < questions.length; i++) {
      final ans = (_ctrls[i]?.text ?? '').trim().toLowerCase();
      final correct = questions[i].correctAnswer.trim().toLowerCase();
      final ok = ans == correct;
      results[i] = ok;
      if (ok) s += questions[i].points;
    }

    setState(() { _results.addAll(results); _score = s; _submitted = true; });

    final auth = context.read<AuthProvider>();
    final prog = context.read<ProgressProvider>();
    final maxScore = questions.fold<int>(0, (a, q) => a + q.points);
    final secs = DateTime.now().difference(_startTime).inSeconds;
    if (auth.isLoggedIn) {
      prog.saveProgress(
        skill: 'listening', lessonId: _lesson.id,
        score: s, maxScore: maxScore, timeSpent: secs,
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kết quả', textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$s / $maxScore',
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold,
                  color: AppTheme.skillListening)),
          const SizedBox(height: 8),
          Text('${results.values.where((v) => v).length}/${questions.length} câu đúng'),
          const SizedBox(height: 4),
          Text('Nghe ${_playCount} lần · ${secs}s',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('Thoát')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _submitted = false; _score = 0; _results.clear();
                _hasListened = false; _playCount = 0;
                for (final c in _ctrls.values) c.clear();
              });
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

    // Khởi tạo controllers
    for (int i = 0; i < questions.length; i++) {
      _ctrls.putIfAbsent(i, () => TextEditingController());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson.title, overflow: TextOverflow.ellipsis),
        backgroundColor: AppTheme.skillListening,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Audio player card ──────────────────────────────────────────
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [AppTheme.skillListening, Color(0xFFBF360C)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Column(children: [
                  const Icon(Icons.headphones_rounded, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(_lesson.title,
                      style: const TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Text('Đã nghe: $_playCount lần',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 20),

                  // Play button
                  GestureDetector(
                    onTap: _play,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        color: _isPlaying ? Colors.red : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                          color: Colors.black26, blurRadius: 12, offset: const Offset(0, 4),
                        )],
                      ),
                      child: Icon(
                        _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        color: _isPlaying ? Colors.white : AppTheme.skillListening,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_isPlaying ? 'Đang phát...' : 'Nhấn để nghe',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            if (!_hasListened)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(child: Text('Nghe bài audio trước khi làm bài tập')),
                ]),
              ),

            if (_hasListened && questions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Câu hỏi (${questions.length} câu)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              ...List.generate(questions.length, (i) {
                final q = questions[i];
                final ctrl = _ctrls[i]!;
                final result = _results[i];

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Câu ${i + 1}: ${q.questionText}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, height: 1.5)),
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
                            onTap: _submitted ? null : () => setState(() => ctrl.text = opt),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(
                                color: bg ?? (ctrl.text == opt
                                    ? AppTheme.skillListening.withOpacity(0.1) : null),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: border ?? (ctrl.text == opt
                                      ? AppTheme.skillListening : Colors.grey.shade300),
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

                      // Fill blank
                      if (q.questionType == 'fill_blank')
                        TextField(
                          controller: ctrl,
                          enabled: !_submitted,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Điền câu trả lời',
                            prefixIcon: const Icon(Icons.edit_outlined),
                            suffixIcon: _submitted
                                ? Icon(result == true
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
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
                          child: Row(children: [
                            const Icon(Icons.check_rounded, color: Colors.green, size: 16),
                            const SizedBox(width: 6),
                            Text('Đáp án: ${q.correctAnswer}',
                                style: const TextStyle(color: Colors.green,
                                    fontWeight: FontWeight.w600)),
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
                        backgroundColor: AppTheme.skillListening),
                    child: const Text('Nộp bài'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
