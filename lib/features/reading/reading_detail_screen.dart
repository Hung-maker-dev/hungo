// lib/features/reading/reading_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/lesson_provider.dart';
import '../../core/providers/progress_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class ReadingDetailScreen extends StatefulWidget {
  final dynamic lesson;
  const ReadingDetailScreen({super.key, required this.lesson});
  @override
  State<ReadingDetailScreen> createState() => _ReadingDetailScreenState();
}

class _ReadingDetailScreenState extends State<ReadingDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final Map<int, String> _answers = {};
  bool _submitted = false;
  int _score = 0;
  final _startTime = DateTime.now();

  LessonModel get _lesson => widget.lesson as LessonModel;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadQuestions(_lesson.id!);
    });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  void _submit(List<QuestionModel> questions) {
    int s = 0;
    for (int i = 0; i < questions.length; i++) {
      if (_answers[i] == questions[i].correctAnswer) s += questions[i].points;
    }
    setState(() { _score = s; _submitted = true; });

    final auth = context.read<AuthProvider>();
    final prog = context.read<ProgressProvider>();
    final maxScore = questions.fold<int>(0, (a, q) => a + q.points);
    final secs = DateTime.now().difference(_startTime).inSeconds;
    if (auth.isLoggedIn) {
      prog.saveProgress(
        skill: 'reading', lessonId: _lesson.id,
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
                  color: AppTheme.primary)),
          const SizedBox(height: 8),
          Text('${_answers.entries.where((e) => e.value == questions[e.key].correctAnswer).length}/${questions.length} câu đúng'),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('Thoát')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _tab.animateTo(1); },
            child: const Text('Xem đáp án'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LessonProvider>();
    final questions = lp.questions;

    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson.title, overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Bài đọc'), Tab(text: 'Câu hỏi')],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ── Bài đọc ─────────────────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.skillReading.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.chrome_reader_mode_rounded,
                      color: AppTheme.skillReading, size: 16),
                  const SizedBox(width: 6),
                  Text('Trình độ ${_lesson.level}',
                      style: const TextStyle(color: AppTheme.skillReading,
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 16),
              if (_lesson.description != null) ...[
                Text(_lesson.description!,
                    style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
                const Divider(height: 24),
              ],
              Text(_lesson.content ?? 'Nội dung đang được cập nhật...',
                  style: const TextStyle(fontSize: 16, height: 1.8)),
              const SizedBox(height: 24),
              if (questions.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _tab.animateTo(1),
                    icon: const Icon(Icons.quiz_rounded),
                    label: const Text('Làm bài kiểm tra'),
                  ),
                ),
            ]),
          ),

          // ── Câu hỏi ─────────────────────────────────────────────────────
          lp.isLoading
              ? const Center(child: CircularProgressIndicator())
              : questions.isEmpty
                  ? const Center(child: Text('Chưa có câu hỏi'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ...List.generate(questions.length, (i) {
                          final q = questions[i];
                          final opts = q.options ?? [];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Câu ${i + 1}: ${q.questionText}',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                const SizedBox(height: 12),
                                ...opts.map((opt) {
                                  Color? bg, border;
                                  if (_submitted) {
                                    if (opt == q.correctAnswer) { bg = Colors.green.shade50; border = Colors.green; }
                                    else if (opt == _answers[i]) { bg = Colors.red.shade50; border = Colors.red; }
                                  } else if (_answers[i] == opt) {
                                    bg = AppTheme.primary.withOpacity(0.08);
                                    border = AppTheme.primary;
                                  }
                                  return GestureDetector(
                                    onTap: _submitted ? null : () => setState(() => _answers[i] = opt),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: bg,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: border ?? Colors.grey.shade300,
                                          width: border != null ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(children: [
                                        Expanded(child: Text(opt)),
                                        if (_submitted && opt == q.correctAnswer)
                                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                                        if (_submitted && opt == _answers[i] && opt != q.correctAnswer)
                                          const Icon(Icons.cancel_rounded, color: Colors.red, size: 18),
                                      ]),
                                    ),
                                  );
                                }),
                                if (_submitted && q.explanation != null) ...[
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text('💡 ${q.explanation}',
                                        style: TextStyle(color: Colors.blue.shade700, fontSize: 13)),
                                  ),
                                ],
                              ]),
                            ),
                          );
                        }),
                        if (!_submitted)
                          ElevatedButton(
                            onPressed: _answers.length == questions.length
                                ? () => _submit(questions) : null,
                            child: const Text('Nộp bài'),
                          ),
                      ],
                    ),
        ],
      ),
    );
  }
}
