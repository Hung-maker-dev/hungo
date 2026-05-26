// lib/features/grammar/grammar_exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/grammar_provider.dart';
import '../../core/providers/progress_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/grammar_checker.dart';
import '../../core/theme/app_theme.dart';

class GrammarExerciseScreen extends StatefulWidget {
  final int grammarId;
  final String grammarName;
  const GrammarExerciseScreen({super.key, required this.grammarId, required this.grammarName});

  @override
  State<GrammarExerciseScreen> createState() => _GrammarExerciseScreenState();
}

class _GrammarExerciseScreenState extends State<GrammarExerciseScreen> {
  int _idx = 0;
  int _score = 0;
  final Map<int, String> _answers = {};
  final Map<int, bool> _results = {};
  bool _submitted = false;
  final _ctrl = TextEditingController();
  final _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GrammarProvider>().loadExercises(widget.grammarId);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _submitAnswer(List exercises) {
    final ex = exercises[_idx];
    final userAns = _ctrl.text.trim();
    if (userAns.isEmpty) return;

    final correct = ex['correct_answer'] as String;
    final isOk = GrammarChecker.checkAnswer(userAns, correct);
    setState(() {
      _answers[_idx] = userAns;
      _results[_idx] = isOk;
      _submitted = true;
      if (isOk) _score += (ex['difficulty'] as int? ?? 1) * 10;
    });
  }

  void _next(List exercises) {
    if (_idx < exercises.length - 1) {
      setState(() { _idx++; _submitted = false; _ctrl.clear(); });
    } else {
      _showResult(exercises);
    }
  }

  void _showResult(List exercises) {
    final secs = DateTime.now().difference(_startTime).inSeconds;
    final auth = context.read<AuthProvider>();
    final prog = context.read<ProgressProvider>();
    final maxScore = exercises.fold<int>(0, (s, e) => s + ((e['difficulty'] as int? ?? 1) * 10));

    if (auth.isLoggedIn) {
      prog.saveProgress(
        skill: 'grammar',
        grammarId: widget.grammarId,
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
          Text('${_results.values.where((v) => v).length}/${exercises.length} câu đúng'),
          const SizedBox(height: 4),
          Text('Thời gian: ${secs}s', style: TextStyle(color: Colors.grey.shade600)),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('Thoát')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() { _idx = 0; _score = 0; _answers.clear(); _results.clear(); _submitted = false; _ctrl.clear(); });
            },
            child: const Text('Làm lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GrammarProvider>();
    final exercises = gp.exercises;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.grammarName),
        bottom: exercises.isEmpty ? null : PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: exercises.isEmpty ? 0 : (_idx + 1) / exercises.length,
            backgroundColor: Colors.white30, color: Colors.white,
          ),
        ),
      ),
      body: gp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : exercises.isEmpty
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
              : _buildExercise(exercises),
    );
  }

  Widget _buildExercise(List exercises) {
    final ex = exercises[_idx];
    final type = ex['question_type'] ?? ex['exercise_type'] ?? 'fill_blank';
    final isCorrect = _results[_idx];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Counter
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Câu ${_idx + 1}/${exercises.length}',
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
                        type == 'fill_blank' ? 'Điền vào chỗ trống' : 'Trắc nghiệm',
                        style: const TextStyle(color: AppTheme.skillGrammar,
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Spacer(),
                    // Difficulty stars
                    Row(children: List.generate(ex['difficulty'] as int? ?? 1,
                        (_) => const Icon(Icons.star_rounded, size: 16, color: Colors.amber))),
                  ]),
                  const SizedBox(height: 14),
                  Text(ex['exercise_text'] as String,
                      style: const TextStyle(fontSize: 17, height: 1.6,
                          fontWeight: FontWeight.w500)),

                  if (ex['hint'] != null) ...[
                    const SizedBox(height: 8),
                    Text('💡 Gợi ý: ${ex['hint']}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // MCQ options
          if (type == 'mcq' && ex['options'] != null) ...[
            ..._parseOptions(ex['options'] as String).map((opt) {
              Color? bg, border;
              if (_submitted) {
                if (opt == ex['correct_answer']) { bg = Colors.green.shade50; border = Colors.green; }
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
                    if (_submitted && opt == ex['correct_answer'])
                      const Icon(Icons.check_circle_rounded, color: Colors.green),
                    if (_submitted && opt == _answers[_idx] && opt != ex['correct_answer'])
                      const Icon(Icons.cancel_rounded, color: Colors.red),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // Fill blank input
          if (type == 'fill_blank') ...[
            TextField(
              controller: _ctrl,
              enabled: !_submitted,
              onChanged: (v) => setState(() {}),
              onSubmitted: (_) => !_submitted ? _submitAnswer(exercises) : null,
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
                  Text('Đáp án đúng: ${ex['correct_answer']}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(_getExplanation(ex),
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
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
                    onPressed: type == 'mcq'
                        ? (_answers.containsKey(_idx)
                            ? () => _submitAnswer(exercises) : null)
                        : (_ctrl.text.isNotEmpty
                            ? () => _submitAnswer(exercises) : null),
                    child: const Text('Kiểm tra'),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _next(exercises),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(_idx < exercises.length - 1 ? 'Câu tiếp' : 'Xem kết quả'),
                  ),
          ),
        ],
      ),
    );
  }

  List<String> _parseOptions(String raw) {
    try {
      return raw.replaceAll('[', '').replaceAll(']', '')
          .replaceAll('"', '').split(',').map((e) => e.trim()).toList();
    } catch (_) { return []; }
  }

  String _getExplanation(Map ex) {
    if (ex['explanation'] != null) return ex['explanation'] as String;
    final result = GrammarChecker.detectTense(ex['correct_answer'] as String? ?? '');
    return result.suggestions.isNotEmpty ? result.suggestions.first : '';
  }
}
