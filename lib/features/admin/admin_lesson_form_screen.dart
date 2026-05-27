// lib/features/admin/admin_lesson_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/lesson_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/models.dart';
import '../../core/services/firebase_storage_service.dart';
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
  String _skill = 'listening';
  String _level = 'A1';
  bool _saving = false;

  String? _audioUrl;
  String? _audioFileName;
  int? _audioSizeKb;
  double _uploadProgress = 0;
  bool _uploading = false;

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
      _audioUrl = l.audioUrl;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    setState(() { _uploading = true; _uploadProgress = 0; });
    final result = await FirebaseStorageService.pickAndUploadAudio(
      lessonTitle: _titleCtrl.text.isEmpty ? 'lesson' : _titleCtrl.text,
      onProgress: (p) => setState(() => _uploadProgress = p),
    );
    setState(() => _uploading = false);
    if (result.cancelled) return;
    if (result.isSuccess) {
      setState(() {
        _audioUrl = result.downloadUrl;
        _audioFileName = result.fileName;
        _audioSizeKb = result.fileSizeKb;
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Upload audio thành công!'), backgroundColor: Colors.green));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.error ?? 'Upload thất bại'), backgroundColor: Colors.red));
    }
  }

  Future<void> _removeAudio() async {
    if (_audioUrl != null) await FirebaseStorageService.deleteAudio(_audioUrl!);
    setState(() { _audioUrl = null; _audioFileName = null; _audioSizeKb = null; });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_skill == 'listening' && _audioUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bài listening cần có file audio!'), backgroundColor: Colors.orange));
      return;
    }
    if (!context.read<AuthProvider>().isAdmin) return;
    setState(() => _saving = true);

    final lp = context.read<LessonProvider>();
    final lesson = LessonModel(
      id: _isEdit ? (widget.lesson as LessonModel).id : null,
      title: _titleCtrl.text.trim(), skill: _skill, level: _level,
      content: _contentCtrl.text.trim(), description: _descCtrl.text.trim(),
      audioUrl: _audioUrl,
    );

    int lessonId;
    if (_isEdit) {
      await lp.updateLesson(lesson);
      lessonId = lesson.id!;
    } else {
      lessonId = await lp.addLesson(lesson);
    }

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      await lp.addQuestion(QuestionModel(
        lessonId: lessonId, questionText: q['question'],
        questionType: q['type'],
        options: q['options'] != null ? List<String>.from(q['options']) : null,
        correctAnswer: q['correct'], explanation: q['explanation'],
        points: q['points'] ?? 10, orderIndex: i,
      ));
    }
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lưu bài học thành công!'), backgroundColor: Colors.green));
    }
  }

  void _addQuestion() {
    final qCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    final opts = List.generate(4, (_) => TextEditingController());
    String type = _skill == 'listening' ? 'fill_blank' : 'mcq';
    final qForm = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (_, ss) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Form(
              key: qForm,
              child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thêm câu hỏi',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'fill_blank', label: Text('Điền từ')),
                      ButtonSegment(value: 'mcq', label: Text('Trắc nghiệm')),
                    ],
                    selected: {type},
                    onSelectionChanged: (v) => ss(() => type = v.first),
                  ),
                  const SizedBox(height: 10),
                  if (type == 'fill_blank')
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text(
                          '💡 Dùng ___ để đánh dấu chỗ trống\n'
                              'Ví dụ: "She ___ to school every day."',
                          style: TextStyle(fontSize: 12, color: Colors.blue)),
                    ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: qCtrl, maxLines: 3,
                    decoration: InputDecoration(
                        labelText: type == 'fill_blank'
                            ? 'Câu có chỗ trống (dùng ___)' : 'Nội dung câu hỏi',
                        hintText: type == 'fill_blank'
                            ? 'She ___ to school every day.' : null),
                    validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 10),
                  if (type == 'mcq') ...[
                    const Text('Các đáp án:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    ...List.generate(4, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextFormField(controller: opts[i],
                          decoration: InputDecoration(labelText: 'Đáp án ${['A','B','C','D'][i]}')),
                    )),
                  ],
                  TextFormField(
                    controller: aCtrl,
                    decoration: const InputDecoration(labelText: 'Đáp án đúng *'),
                    validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: expCtrl,
                      decoration: const InputDecoration(labelText: 'Giải thích (tùy chọn)')),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!qForm.currentState!.validate()) return;
                        setState(() => _questions.add({
                          'question': qCtrl.text.trim(), 'type': type,
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
            onPressed: (_saving || _uploading) ? null : _save,
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
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: _skill,
                decoration: const InputDecoration(labelText: 'Loại kỹ năng'),
                items: ['reading','listening','grammar','writing']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _skill = v!),
              )),
              const SizedBox(width: 12),
              Expanded(child: DropdownButtonFormField<String>(
                value: _level,
                decoration: const InputDecoration(labelText: 'Trình độ'),
                items: ['A1','A2','B1','B2','C1','C2']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => setState(() => _level = v!),
              )),
            ]),
            const SizedBox(height: 14),
            TextFormField(controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Tiêu đề bài học *'),
                validator: (v) => v!.isEmpty ? 'Bắt buộc' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Mô tả ngắn'), maxLines: 2),
            const SizedBox(height: 16),

            // ── AUDIO UPLOAD (chỉ listening) ─────────────────────────────
            if (_skill == 'listening') ...[
              const Text('🎵 File Audio *',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              if (_audioUrl == null)
                InkWell(
                  onTap: _uploading ? null : _pickAndUpload,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.skillListening, width: 2),
                      borderRadius: BorderRadius.circular(14),
                      color: AppTheme.skillListening.withOpacity(0.05),
                    ),
                    child: _uploading
                        ? Column(children: [
                      Text('Đang upload... ${(_uploadProgress * 100).round()}%',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: _uploadProgress,
                          color: AppTheme.skillListening),
                    ])
                        : const Column(children: [
                      Icon(Icons.upload_file_rounded,
                          size: 48, color: AppTheme.skillListening),
                      SizedBox(height: 8),
                      Text('Nhấn để chọn file audio',
                          style: TextStyle(fontWeight: FontWeight.w600,
                              color: AppTheme.skillListening)),
                      SizedBox(height: 4),
                      Text('Hỗ trợ: mp3, wav, m4a, aac',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ]),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(children: [
                    const Icon(Icons.audio_file_rounded, color: Colors.green, size: 36),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_audioFileName ?? 'Audio file',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (_audioSizeKb != null)
                        Text('${_audioSizeKb}KB',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const Text('✅ Đã upload lên Firebase',
                          style: TextStyle(color: Colors.green, fontSize: 12)),
                    ])),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: _removeAudio,
                    ),
                  ]),
                ),
              if (_audioUrl != null) ...[
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: _pickAndUpload,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Đổi file khác'),
                ),
              ],
              const SizedBox(height: 16),
            ],

            // ── CONTENT ──────────────────────────────────────────────────
            TextFormField(
              controller: _contentCtrl,
              decoration: InputDecoration(
                labelText: _skill == 'listening'
                    ? 'Script bài nghe (hiện sau khi nộp bài)'
                    : 'Nội dung bài đọc *',
                alignLabelWithHint: true,
                hintText: _skill == 'listening'
                    ? 'Nội dung audio, hiển thị sau khi user nộp bài...'
                    : 'Nhập đoạn văn...',
              ),
              maxLines: 8,
              validator: (v) => _skill != 'listening' && v!.isEmpty ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 20),

            // ── QUESTIONS ────────────────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Câu hỏi (${_questions.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                onPressed: _addQuestion,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm câu hỏi'),
              ),
            ]),
            if (_questions.isEmpty && _skill == 'listening')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300)),
                child: const Text(
                    '💡 Thêm câu hỏi dạng "Điền từ" cho bài nghe.\n'
                        'Dùng ___ cho chỗ trống. Ví dụ: "She ___ every day."',
                    style: TextStyle(fontSize: 13)),
              ),
            ..._questions.asMap().entries.map((e) => Card(
              margin: const EdgeInsets.only(top: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                  child: Text('${e.key+1}', style: const TextStyle(
                      color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ),
                title: Text(e.value['question'] as String,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                    '${e.value['type'] == 'fill_blank' ? '📝 Điền từ' : '🔤 Trắc nghiệm'}'
                        ' · Đáp án: ${e.value['correct']}',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: () => setState(() => _questions.removeAt(e.key)),
                ),
              ),
            )),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
