// lib/features/admin/admin_lesson_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/lesson_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class AdminLessonFormScreen extends StatefulWidget {
  final dynamic lesson;
  const AdminLessonFormScreen({super.key, this.lesson});
  @override
  State<AdminLessonFormScreen> createState() => _AdminLessonFormScreenState();
}

class _AdminLessonFormScreenState extends State<AdminLessonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _skill = 'reading';
  String _level = 'A1';
  bool _saving = false;

  // Questions
  final List<Map<String, dynamic>> _questions = [];

  bool get _isEdit => widget.lesson is LessonModel;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final l = widget.lesson as LessonModel;
      _titleCtrl.text = l.title;
      _descCtrl.text = l.description ?? '';
      _contentCtrl.text = l.content ?? '';
      _skill = l.skill;
      _level = l.level;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isAdmin) return;
    setState(() => _saving = true);

    final lp = context.read<LessonProvider>();
    final lesson = LessonModel(
      id: _isEdit ? (widget.lesson as LessonModel).id : null,
      title: _titleCtrl.text.trim(),
      skill: _skill, level: _level,
      content: _contentCtrl.text.trim(),
      description: _descCtrl.text.trim(),
    );

    int lessonId;
    if (_isEdit) {
      await lp.updateLesson(lesson);
      lessonId = lesson.id!;
    } else {
      lessonId = await lp.addLesson(lesson);
    }

    // Save questions
    for (final q in _questions) {
      await lp.addQuestion(QuestionModel(
        lessonId: lessonId,
        questionText: q['question'],
        questionType: q['type'],
        options: q['options'] != null ? List<String>.from(q['options']) : null,
        correctAnswer: q['correct'],
        explanation: q['explanation'],
        points: q['points'] ?? 10,
        orderIndex: _questions.indexOf(q),
      ));
    }

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Lưu bài học thành công!'),
        backgroundColor: Colors.green,
      ));
    }
  }

  void _addQuestion() {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final opts = [TextEditingController(), TextEditingController(),
        TextEditingController(), TextEditingController()];
    String type = 'mcq';
    final qForm = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: qForm,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thêm câu hỏi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'mcq', label: Text('Trắc nghiệm')),
                      ButtonSegment(value: 'fill_blank', label: Text('Điền từ')),
                    ],
                    selected: {type},
                    onSelectionChanged: (v) => setS(() => type = v.first),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: qCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Nội dung câu hỏi *'),
                    validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 12),
                  if (type == 'mcq') ...[
                    const Text('Các đáp án (A/B/C/D):',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    ...List.generate(4, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextFormField(
                        controller: opts[i],
                        decoration: InputDecoration(labelText: 'Đáp án ${['A','B','C','D'][i]}'),
                      ),
                    )),
                  ],
                  TextFormField(
                    controller: aCtrl,
                    decoration: InputDecoration(
                      labelText: type == 'mcq' ? 'Đáp án đúng (gõ nguyên đáp án)' : 'Đáp án đúng *',
                    ),
                    validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: expCtrl,
                    decoration: const InputDecoration(labelText: 'Giải thích (tùy chọn)'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!qForm.currentState!.validate()) return;
                        setState(() => _questions.add({
                          'question': qCtrl.text.trim(),
                          'type': type,
                          'options': type == 'mcq'
                              ? opts.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList()
                              : null,
                          'correct': aCtrl.text.trim(),
                          'explanation': expCtrl.text.trim().isEmpty ? null : expCtrl.text.trim(),
                          'points': 10,
                        }));
                        Navigator.pop(ctx);
                      },
                      child: const Text('Thêm câu hỏi'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa bài học' : 'Thêm bài học'),
        backgroundColor: Colors.red.shade700,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Loại bài + trình độ
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _skill,
                  decoration: const InputDecoration(labelText: 'Loại kỹ năng'),
                  items: ['reading', 'listening', 'grammar', 'writing'].map((s) =>
                    DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _skill = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _level,
                  decoration: const InputDecoration(labelText: 'Trình độ'),
                  items: ['A1','A2','B1','B2','C1','C2'].map((l) =>
                    DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (v) => setState(() => _level = v!),
                ),
              ),
            ]),
            const SizedBox(height: 14),

            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Tiêu đề bài học *'),
              validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Mô tả ngắn'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentCtrl,
              decoration: const InputDecoration(
                labelText: 'Nội dung bài (đoạn văn / script nghe) *',
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 20),

            // Questions section
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Câu hỏi (${_questions.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm'),
              ),
            ]),
            ..._questions.asMap().entries.map((e) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text('${e.key + 1}',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
              title: Text(e.value['question'] as String,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${e.value['type']} · Đáp án: ${e.value['correct']}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                onPressed: () => setState(() => _questions.removeAt(e.key)),
              ),
            )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
