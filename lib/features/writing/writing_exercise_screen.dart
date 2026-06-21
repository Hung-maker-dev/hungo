// lib/features/writing/writing_exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/lesson_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/models.dart';
import '../../core/providers/submission_provider.dart';
import '../../core/theme/app_theme.dart';

class WritingExerciseScreen extends StatefulWidget {
  final dynamic lesson;
  const WritingExerciseScreen({super.key, required this.lesson});
  @override
  State<WritingExerciseScreen> createState() => _WritingExerciseScreenState();
}

class _WritingExerciseScreenState extends State<WritingExerciseScreen> {
  static const _color = Color(0xFF6A1B9A);
  final Map<int, TextEditingController> _ctrls    = {};
  final Map<int, bool>                  _submitted = {}; // per-question
  bool   _submittingAll = false;
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

  bool _isWritingType(String type) =>
      type == 'writing' || type == 'writing_prompt' || type == 'sentence_rewrite';

  // ── Nộp 1 câu hỏi writing ────────────────────────────────────────────────
  Future<void> _submitOne(QuestionModel q, int index) async {
    final ctrl = _ctrls[index];
    if (ctrl == null || ctrl.text.trim().isEmpty) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đăng nhập để nộp bài')));
      return;
    }

    setState(() => _submittingAll = true);

    await context.read<SubmissionProvider>().submitAnswer(
      lessonId:   _lesson.id!,
      questionId: q.id!,
      userId:     auth.currentUser!.id!,
      answerText: ctrl.text.trim(),
      maxScore:   q.points,
    );

    setState(() {
      _submitted[index] = true;
      _submittingAll    = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text('Đã nộp! Admin sẽ chấm điểm sớm.'),
          ]),
          backgroundColor: _color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ── Nộp lại (tạo submission mới) ─────────────────────────────────────────
  Future<void> _resubmitOne(QuestionModel q, int index) async {
    setState(() => _submitted[index] = false);
    _ctrls[index]?.clear();
  }

  @override
  Widget build(BuildContext context) {
    final lp        = context.watch<LessonProvider>();
    final questions = lp.questions;
    for (int i = 0; i < questions.length; i++) {
      _ctrls.putIfAbsent(i, () => TextEditingController());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson.title, overflow: TextOverflow.ellipsis),
        backgroundColor: _color,
      ),
      body: lp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Đề bài header
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [_color, _color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.assignment_outlined,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Đề bài',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      _lesson.content ??
                          _lesson.description ??
                          'Làm bài tập viết bên dưới',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15, height: 1.6),
                    ),
                  ]),
            ),
          ),
          const SizedBox(height: 16),

          if (questions.isEmpty)
            const Center(child: Text('Chưa có câu hỏi'))
          else
            ...List.generate(questions.length, (i) {
              final q         = questions[i];
              final ctrl      = _ctrls[i]!;
              final isWriting = _isWritingType(q.questionType);
              final isDone    = _submitted[i] == true;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tiêu đề câu
                        Row(children: [
                          Expanded(
                            child: Text(
                              'Câu ${i + 1}: ${q.questionText}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  height: 1.5),
                            ),
                          ),
                          if (isDone)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.orange.shade300),
                              ),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.pending_outlined,
                                        size: 14,
                                        color: Colors.orange.shade700),
                                    const SizedBox(width: 4),
                                    Text('Đang chấm',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w600)),
                                  ]),
                            ),
                        ]),
                        const SizedBox(height: 12),

                        // MCQ (không thay đổi)
                        if (q.questionType == 'mcq' && q.options != null)
                          ...q.options!.map((opt) => GestureDetector(
                            onTap: isDone
                                ? null
                                : () => setState(() => ctrl.text = opt),
                            child: AnimatedContainer(
                              duration:
                              const Duration(milliseconds: 150),
                              margin:
                              const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(
                                color: ctrl.text == opt
                                    ? _color.withOpacity(0.1)
                                    : null,
                                borderRadius:
                                BorderRadius.circular(10),
                                border: Border.all(
                                  color: ctrl.text == opt
                                      ? _color
                                      : Colors.grey.shade300,
                                  width: ctrl.text == opt ? 2 : 1,
                                ),
                              ),
                              child: Text(opt),
                            ),
                          )),

                        // Gợi ý sentence_rewrite
                        if (q.questionType == 'sentence_rewrite') ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(children: [
                              const Icon(Icons.lightbulb_outline_rounded,
                                  color: Colors.purple, size: 16),
                              const SizedBox(width: 6),
                              const Text(
                                  'Viết thành câu đúng từ các từ gợi ý',
                                  style: TextStyle(
                                      color: Colors.purple, fontSize: 12)),
                            ]),
                          ),
                        ],

                        // Text field writing
                        if (isWriting) ...[
                          if (isDone)
                          // Hiện bài đã nộp (read-only)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.grey.shade300),
                              ),
                              child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text('Bài đã nộp:',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 6),
                                    Text(ctrl.text,
                                        style: const TextStyle(
                                            fontSize: 14, height: 1.5)),
                                  ]),
                            )
                          else
                            TextField(
                              controller: ctrl,
                              maxLines: q.questionType == 'writing_prompt'
                                  ? 8
                                  : 3,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText:
                                q.questionType == 'writing_prompt'
                                    ? 'Viết bài của bạn tại đây...'
                                    : q.questionType ==
                                    'sentence_rewrite'
                                    ? 'Viết câu đúng...'
                                    : 'Viết câu trả lời...',
                                prefixIcon:
                                const Icon(Icons.edit_outlined),
                                border: const OutlineInputBorder(),
                                hintText: q.questionType ==
                                    'writing_prompt'
                                    ? 'Tối thiểu 50 từ...'
                                    : null,
                              ),
                            ),
                        ],

                        const SizedBox(height: 12),

                        // Nút nộp / nộp lại
                        if (isWriting)
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isDone) ...[
                                  TextButton.icon(
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 16),
                                    label: const Text('Nộp lại'),
                                    onPressed: () => _resubmitOne(q, i),
                                    style: TextButton.styleFrom(
                                        foregroundColor: _color),
                                  ),
                                ] else ...[
                                  Text(
                                    '${ctrl.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} từ',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    icon: _submittingAll
                                        ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                        : const Icon(Icons.send_rounded,
                                        size: 16),
                                    label: const Text('Nộp bài'),
                                    onPressed: ctrl.text.trim().isEmpty ||
                                        _submittingAll
                                        ? null
                                        : () => _submitOne(q, i),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _color,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                    ),
                                  ),
                                ],
                              ]),
                      ]),
                ),
              );
            }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}