// lib/features/grammar/grammar_exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/lesson_provider.dart';
import '../../core/providers/progress_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/grammar_checker.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class GrammarExerciseScreen extends StatefulWidget {
  final String grammarTopic; // tên thì, VD: "Simple Present" — dùng để tìm lesson tương ứng
  final String grammarName;  // tên hiển thị trên AppBar
  const GrammarExerciseScreen({
    super.key,
    required this.grammarTopic,
    required this.grammarName,
  });

  @override
  State<GrammarExerciseScreen> createState() => _GrammarExerciseScreenState();
}

class _GrammarExerciseScreenState extends State<GrammarExerciseScreen> {
  int _idx = 0;
  int _score = 0;
  final Map<int, String> _answers = {};
  final Map<int, bool> _results = {};
  bool _submitted = false;
  bool _loading = true;
  final _ctrl = TextEditingController();
  final _startTime = DateTime.now();

  LessonModel? _lesson;
  List<QuestionModel> _questions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final lp = context.read<LessonProvider>();
    final lesson = lp.getGrammarLessonByTopic(widget.grammarTopic);

    if (lesson == null || lesson.id == null) {
      setState(() {
        _lesson = null;
        _questions = [];
        _loading = false;
      });
      return;
    }

    final qs = await lp.loadQuestions(lesson.id!);
    setState(() {
      _lesson = lesson;
      _questions = qs;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submitAnswer() {
    final q = _questions[_idx];
    final userAns = _ctrl.text.trim();
    if (userAns.isEmpty) return;

    final isOk = GrammarChecker.checkAnswer(userAns, q.correctAnswer);
    setState(() {
      _answers[_idx] = userAns;
      _results[_idx] = isOk;
      _submitted = true;
      if (isOk) _score += q.points;
    });
  }

  void _next() {
    if (_idx < _questions.length - 1) {
      setState(() {
        _idx++;
        _submitted = false;
        _ctrl.clear();
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    final secs = DateTime.now().difference(_startTime).inSeconds;
    final auth = context.read<AuthProvider>();
    final prog = context.read<ProgressProvider>();
    final maxScore = _questions.fold<int>(0, (s, q) => s + q.points);

    if (auth.isLoggedIn && _lesson != null) {
      prog.saveProgress(
        skill: 'grammar',
        lessonId: _lesson!.id,
        score: _score,
        maxScore: maxScore,
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
          Text(widget.grammarName,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('$_score / $maxScore',
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold,
                  color: AppTheme.primary)),
          const SizedBox(height: 8),
          Text('${_results.values.where((v) => v).length}/${_questions.length} câu đúng'),
          const SizedBox(height: 4),
          Text('Thời gian: ${secs}s', style: TextStyle(color: Colors.grey.shade600)),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('Thoát')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _idx = 0; _score = 0;
                _answers.clear(); _results.clear();
                _submitted = false; _ctrl.clear();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.grammarName),
        bottom: _questions.isEmpty ? null : PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _questions.isEmpty ? 0 : (_idx + 1) / _questions.length,
            backgroundColor: Colors.white30, color: Colors.white,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
          ? Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.assignment_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Chưa có bài tập cho chủ đề này'),
          const SizedBox(height: 8),
          Text('Admin sẽ thêm bài tập sớm!',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: () => Navigator.pop(context),
              child: const Text('Quay lại')),
        ]),
      )
          : _buildExercise(),
    );
  }

  Widget _buildExercise() {
    final q = _questions[_idx];
    final type = q.questionType; // 'fill_blank' | 'mcq' | 'true_false' | 'sentence_rewrite'
    final isCorrect = _results[_idx];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Counter
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Câu ${_idx + 1}/${_questions.length}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Row(children: [
              Icon(Icons.star_rounded, color: Colors.amber.shade600, size: 18),
              const SizedBox(width: 4),
              Text('$_score điểm'),
            ]),
          ]),
          const SizedBox(height: 20),

          // Exercise card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.skillGrammar.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _typeLabel(type),
                        style: const TextStyle(color: AppTheme.skillGrammar,
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Spacer(),
                    Text('${q.points} điểm',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ]),
                  const SizedBox(height: 14),
                  Text(q.questionText,
                      style: const TextStyle(fontSize: 17, height: 1.6,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // MCQ options
          if (type == 'mcq' && q.options != null) ...[
            ...q.options!.map((opt) {
              Color? bg, border;
              if (_submitted) {
                if (opt == q.correctAnswer) { bg = Colors.green.shade50; border = Colors.green; }
                else if (opt == _answers[_idx]) { bg = Colors.red.shade50; border = Colors.red; }
              }
              return GestureDetector(
                onTap: _submitted ? null : () {
                  setState(() { _answers[_idx] = opt; _ctrl.text = opt; });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bg ?? (_answers[_idx] == opt
                        ? AppTheme.primary.withOpacity(0.1) : null),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: border ?? (_answers[_idx] == opt
                          ? AppTheme.primary : Colors.grey.shade300),
                      width: border != null || _answers[_idx] == opt ? 2 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(opt, style: const TextStyle(fontSize: 15))),
                    if (_submitted && opt == q.correctAnswer)
                      const Icon(Icons.check_circle_rounded, color: Colors.green),
                    if (_submitted && opt == _answers[_idx] && opt != q.correctAnswer)
                      const Icon(Icons.cancel_rounded, color: Colors.red),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // true_false options
          if (type == 'true_false') ...[
            ...['True', 'False'].map((opt) {
              Color? bg, border;
              if (_submitted) {
                if (opt.toLowerCase() == q.correctAnswer.toLowerCase()) { bg = Colors.green.shade50; border = Colors.green; }
                else if (opt == _answers[_idx]) { bg = Colors.red.shade50; border = Colors.red; }
              }
              return GestureDetector(
                onTap: _submitted ? null : () {
                  setState(() { _answers[_idx] = opt; _ctrl.text = opt; });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: bg ?? (_answers[_idx] == opt
                        ? AppTheme.primary.withOpacity(0.1) : null),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: border ?? (_answers[_idx] == opt
                          ? AppTheme.primary : Colors.grey.shade300),
                      width: border != null || _answers[_idx] == opt ? 2 : 1,
                    ),
                  ),
                  child: Text(opt, style: const TextStyle(fontSize: 15)),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // sentence_rewrite hint
          if (type == 'sentence_rewrite') ...[
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: const Row(children: [
                Icon(Icons.auto_fix_high_rounded, color: Colors.purple, size: 16),
                SizedBox(width: 6),
                Expanded(child: Text(
                  'Sắp xếp / viết lại thành câu hoàn chỉnh đúng ngữ pháp',
                  style: TextStyle(color: Colors.purple, fontSize: 12),
                )),
              ]),
            ),
          ],

          // Fill blank / sentence_rewrite input
          if (type == 'fill_blank' || type == 'sentence_rewrite') ...[
            TextField(
              controller: _ctrl,
              enabled: !_submitted,
              onChanged: (v) => setState(() {}),
              onSubmitted: (_) => !_submitted ? _submitAnswer() : null,
              decoration: InputDecoration(
                labelText: 'Câu trả lời của bạn',
                prefixIcon: const Icon(Icons.edit_rounded),
                suffixIcon: _ctrl.text.isNotEmpty && !_submitted
                    ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _ctrl.clear()))
                    : null,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Feedback after submit
          if (_submitted) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (isCorrect ?? false) ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isCorrect ?? false) ? Colors.green.shade300 : Colors.red.shade300,
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon((isCorrect ?? false) ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: (isCorrect ?? false) ? Colors.green : Colors.red),
                  const SizedBox(width: 8),
                  Text((isCorrect ?? false) ? 'Chính xác! 🎉' : 'Chưa đúng',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (isCorrect ?? false) ? Colors.green.shade700 : Colors.red.shade700)),
                ]),
                if (!(isCorrect ?? false)) ...[
                  const SizedBox(height: 8),
                  Text('Đáp án đúng: ${q.correctAnswer}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (_getExplanation(q).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(_getExplanation(q),
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                  ],
                ],
              ]),
            ),
            const SizedBox(height: 12),
          ],

          // Buttons
          SizedBox(
            width: double.infinity,
            child: !_submitted
                ? ElevatedButton(
              onPressed: (type == 'mcq' || type == 'true_false')
                  ? (_answers.containsKey(_idx)
                  ? () => _submitAnswer() : null)
                  : (_ctrl.text.isNotEmpty
                  ? () => _submitAnswer() : null),
              child: const Text('Kiểm tra'),
            )
                : ElevatedButton.icon(
              onPressed: () => _next(),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(_idx < _questions.length - 1 ? 'Câu tiếp' : 'Xem kết quả'),
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'fill_blank':       return 'Điền vào chỗ trống';
      case 'mcq':              return 'Trắc nghiệm';
      case 'true_false':       return 'Đúng / Sai';
      case 'sentence_rewrite': return 'Viết lại câu';
      default:                 return type;
    }
  }

  String _getExplanation(QuestionModel q) {
    if (q.explanation != null && q.explanation!.isNotEmpty) return q.explanation!;
    final result = GrammarChecker.detectTense(q.correctAnswer);
    return result.suggestions.isNotEmpty ? result.suggestions.first : '';
  }
}