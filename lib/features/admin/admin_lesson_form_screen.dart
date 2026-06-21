// lib/features/admin/admin_lesson_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/lesson_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/models.dart';
import '../../core/services/local_audio_service.dart';
import '../../core/theme/app_theme.dart';

class AdminLessonFormScreen extends StatefulWidget {
  final dynamic lesson;
  const AdminLessonFormScreen({super.key, this.lesson});
  @override
  State<AdminLessonFormScreen> createState() => _AdminLessonFormScreenState();
}

class _AdminLessonFormScreenState extends State<AdminLessonFormScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _titleCtrl   = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _skill  = 'reading';
  String _level  = 'A1';
  bool   _saving = false;

  // ← THÊM: state cho dropdown thì ngữ pháp
  String _grammarTopic = 'Simple Present';

  // Audio (chỉ dùng cho listening)
  String? _audioLocalPath;
  String? _audioFileName;
  int?    _audioSizeKb;
  bool    _picking = false;

  final List<Map<String, dynamic>> _questions = [];
  bool get _isEdit => widget.lesson is LessonModel;

  // ← THÊM: danh sách 12 thì
  static const _grammarTenses = [
    ('Simple Present',             'Hiện tại đơn'),
    ('Present Continuous',         'Hiện tại tiếp diễn'),
    ('Present Perfect',            'Hiện tại hoàn thành'),
    ('Present Perfect Continuous', 'Hiện tại hoàn thành tiếp diễn'),
    ('Simple Past',                'Quá khứ đơn'),
    ('Past Continuous',            'Quá khứ tiếp diễn'),
    ('Past Perfect',               'Quá khứ hoàn thành'),
    ('Past Perfect Continuous',    'Quá khứ hoàn thành tiếp diễn'),
    ('Simple Future',              'Tương lai đơn'),
    ('Future Continuous',          'Tương lai tiếp diễn'),
    ('Future Perfect',             'Tương lai hoàn thành'),
    ('Future Perfect Continuous',  'Tương lai hoàn thành tiếp diễn'),
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final l = widget.lesson as LessonModel;
      _titleCtrl.text   = l.title;
      _descCtrl.text    = l.description ?? '';
      _contentCtrl.text = l.content ?? '';
      _audioLocalPath   = l.audioUrl;
      if (_audioLocalPath != null) {
        _audioFileName = _audioLocalPath!.split('/').last;
      }
      _skill = l.skill;
      _level = l.level;
      // ← THÊM: khôi phục grammarTopic khi edit
      if (l.skill == 'grammar' && l.topic != null) {
        _grammarTopic = l.topic!;
      }
      _loadExistingQuestions(l.id!);
    } else if (widget.lesson is Map) {
      _skill = (widget.lesson as Map)['defaultSkill'] ?? 'reading';
    }
  }

  Future<void> _loadExistingQuestions(int lessonId) async {
    final lp = context.read<LessonProvider>();
    final questions = await lp.loadQuestions(lessonId);
    setState(() {
      _questions.clear();
      for (final q in questions) {
        _questions.add({
          'id': q.id,
          'question': q.questionText,
          'type': q.questionType,
          'options': q.options != null ? List<String>.from(q.options!) : null,
          'correct': q.correctAnswer,
          'explanation': q.explanation,
          'points': q.points,
        });
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose(); _contentCtrl.dispose();
    super.dispose();
  }

  // ── Audio ─────────────────────────────────────────────────────────────────
  Future<void> _pickAudio() async {
    setState(() => _picking = true);
    final result = await LocalAudioService.pickAndCopyAudio();
    setState(() => _picking = false);
    if (result.cancelled) return;
    if (result.isSuccess) {
      setState(() {
        _audioLocalPath = result.localPath;
        _audioFileName  = result.fileName;
        _audioSizeKb    = result.fileSizeKb;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Đã thêm file audio!'), backgroundColor: Colors.green));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.error ?? 'Lỗi chọn file'),
            backgroundColor: Colors.red));
      }
    }
  }

  // ── Lưu ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_skill == 'listening' && _audioLocalPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bài listening cần có file audio!'),
          backgroundColor: Colors.orange));
      return;
    }
    if (!context.read<AuthProvider>().isAdmin) return;
    setState(() => _saving = true);

    final lp = context.read<LessonProvider>();
    final lesson = LessonModel(
      id: _isEdit ? (widget.lesson as LessonModel).id : null,
      title: _titleCtrl.text.trim(), skill: _skill, level: _level,
      content: _contentCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      audioUrl: _audioLocalPath,
      topic: _skill == 'grammar' ? _grammarTopic : null, // ← THÊM
    );

    int lessonId;
    if (_isEdit) {
      await lp.updateLesson(lesson);
      lessonId = lesson.id!;
      await lp.deleteQuestionsForLesson(lessonId);
    } else {
      lessonId = await lp.addLesson(lesson);
    }

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      await lp.addQuestion(QuestionModel(
        lessonId: lessonId,
        questionText: q['question'] as String,
        questionType: q['type'] as String,
        options: q['options'] != null ? List<String>.from(q['options'] as List) : null,
        correctAnswer: q['correct'] as String,
        explanation: q['explanation'] as String?,
        points: q['points'] as int? ?? 10,
        orderIndex: i,
      ));
    }

    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lưu bài học thành công!'),
          backgroundColor: Colors.green));
    }
  }

  // ── Dialog thêm / sửa câu hỏi ───────────────────────────────────────────
  void _openQuestionDialog({Map<String, dynamic>? existing, int? index}) {
    final qCtrl   = TextEditingController(text: existing?['question'] ?? '');
    final aCtrl   = TextEditingController(text: existing?['correct'] ?? '');
    final expCtrl = TextEditingController(text: existing?['explanation'] ?? '');
    final opts    = List.generate(4, (i) {
      final list = existing?['options'] as List?;
      return TextEditingController(text: list != null && i < list.length ? list[i] : '');
    });

    String type = existing?['type'] ??
        (_skill == 'listening'  ? 'fill_blank'
            : _skill == 'grammar'   ? 'fill_blank'
            : _skill == 'writing'   ? 'writing_prompt'
            : 'mcq');

    String selectedLetter = '';
    if (existing != null && existing['type'] == 'mcq' && existing['options'] != null) {
      final opts2 = (existing['options'] as List).cast<String>();
      final idx2  = opts2.indexOf(existing['correct'] as String);
      if (idx2 >= 0) selectedLetter = ['A','B','C','D'][idx2];
    }

    final qForm = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (_, ss) {
          List<ButtonSegment<String>> segments;
          if (_skill == 'listening') {
            segments = const [
              ButtonSegment(value: 'fill_blank', label: Text('Điền từ')),
              ButtonSegment(value: 'mcq',        label: Text('Trắc nghiệm')),
            ];
          } else if (_skill == 'grammar') {
            segments = const [
              ButtonSegment(value: 'fill_blank',       label: Text('Điền từ')),
              ButtonSegment(value: 'mcq',              label: Text('Trắc nghiệm')),
              ButtonSegment(value: 'sentence_rewrite', label: Text('Viết câu')),
            ];
          } else if (_skill == 'writing') {
            segments = const [
              ButtonSegment(value: 'writing_prompt', label: Text('Đề bài')),
              ButtonSegment(value: 'fill_blank',     label: Text('Điền từ')),
            ];
          } else {
            segments = const [
              ButtonSegment(value: 'mcq',        label: Text('Trắc nghiệm')),
              ButtonSegment(value: 'fill_blank', label: Text('Điền từ')),
              ButtonSegment(value: 'true_false', label: Text('Đúng/Sai')),
            ];
          }

          return Padding(
            padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Form(
                key: qForm,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(
                          existing == null ? 'Thêm câu hỏi' : 'Sửa câu hỏi',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18))),
                      IconButton(icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx)),
                    ]),
                    const SizedBox(height: 12),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<String>(
                        segments: segments,
                        selected: {type},
                        onSelectionChanged: (v) =>
                            ss(() { type = v.first; aCtrl.clear(); selectedLetter = ''; }),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (type == 'fill_blank')
                      _HintBox(color: Colors.blue,
                          text: 'Dùng ___ để đánh dấu chỗ trống\nVD: She ___ to school every day.'),
                    if (type == 'sentence_rewrite')
                      _HintBox(color: Colors.purple,
                          text: 'Cho các từ gợi ý, yêu cầu viết thành câu đúng\nVD: i / go → I am going'),
                    if (type == 'writing_prompt')
                      _HintBox(color: Colors.teal,
                          text: 'Nhập đề bài viết. Đáp án mẫu sẽ hiển thị sau khi nộp.'),
                    if (type == 'true_false')
                      _HintBox(color: Colors.orange,
                          text: 'Đáp án đúng nhập: True hoặc False'),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: qCtrl, maxLines: 3,
                      decoration: InputDecoration(
                        labelText: _questionLabel(type),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null,
                    ),
                    const SizedBox(height: 12),

                    if (type == 'mcq') ...[
                      const Text('Các đáp án:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...List.generate(4, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selectedLetter == ['A','B','C','D'][i]
                                  ? Colors.green
                                  : Colors.grey.shade200,
                            ),
                            child: Center(child: Text(['A','B','C','D'][i],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: selectedLetter == ['A','B','C','D'][i]
                                        ? Colors.white : Colors.grey.shade700))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: TextFormField(
                            controller: opts[i],
                            decoration: InputDecoration(
                              labelText: 'Đáp án ${['A','B','C','D'][i]}',
                              border: const OutlineInputBorder(),
                              suffixIcon: selectedLetter == ['A','B','C','D'][i]
                                  ? const Icon(Icons.check_circle_rounded,
                                  color: Colors.green)
                                  : null,
                            ),
                            onChanged: (_) {
                              if (selectedLetter == ['A','B','C','D'][i]) {
                                aCtrl.text = opts[i].text.trim();
                              }
                              ss(() {});
                            },
                          )),
                        ]),
                      )),
                      const SizedBox(height: 8),
                      const Text('Chọn đáp án đúng:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: ['A','B','C','D'].map((letter) {
                        final idx = ['A','B','C','D'].indexOf(letter);
                        final isSelected = selectedLetter == letter;
                        return GestureDetector(
                          onTap: () {
                            final content = opts[idx].text.trim();
                            if (content.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                  content: Text('Nhập nội dung đáp án $letter trước!'),
                                  duration: Duration(seconds: 1)));
                              return;
                            }
                            ss(() {
                              selectedLetter = letter;
                              aCtrl.text = content;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.green : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: isSelected ? Colors.green : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              if (isSelected) ...[
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 4),
                              ],
                              Text(letter, style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isSelected ? Colors.white
                                      : Colors.grey.shade700)),
                            ]),
                          ),
                        );
                      }).toList()),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: aCtrl.text.isEmpty
                              ? Colors.grey.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: aCtrl.text.isEmpty
                                  ? Colors.grey.shade300
                                  : Colors.green.shade300),
                        ),
                        child: Row(children: [
                          Icon(
                              aCtrl.text.isEmpty
                                  ? Icons.radio_button_unchecked
                                  : Icons.check_circle_rounded,
                              color: aCtrl.text.isEmpty ? Colors.grey : Colors.green,
                              size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            aCtrl.text.isEmpty
                                ? '⚠️ Chưa chọn đáp án đúng'
                                : '✅ Đáp án đúng: ${aCtrl.text}',
                            style: TextStyle(
                                fontSize: 13,
                                color: aCtrl.text.isEmpty
                                    ? Colors.grey.shade600 : Colors.green.shade700,
                                fontWeight: FontWeight.w500),
                          )),
                        ]),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: aCtrl,
                        decoration: InputDecoration(
                          labelText: _answerLabel(type),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.check_circle_outline_rounded,
                              color: Colors.green),
                        ),
                        validator: (v) => type != 'writing_prompt' && v!.trim().isEmpty
                            ? 'Bắt buộc' : null,
                      ),
                    ],

                    const SizedBox(height: 10),
                    TextFormField(
                      controller: expCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Giải thích (tùy chọn)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(existing == null ? Icons.add_rounded : Icons.save_rounded),
                        label: Text(existing == null ? 'Thêm câu hỏi' : 'Lưu thay đổi'),
                        onPressed: () {
                          if (!qForm.currentState!.validate()) return;
                          if (type == 'mcq' && aCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                content: Text('Vui lòng chọn đáp án đúng (A/B/C/D)!'),
                                backgroundColor: Colors.orange));
                            return;
                          }
                          final newQ = {
                            'question': qCtrl.text.trim(),
                            'type': type,
                            'options': type == 'mcq'
                                ? opts.map((c) => c.text.trim())
                                .where((s) => s.isNotEmpty).toList()
                                : null,
                            'correct': aCtrl.text.trim(),
                            'explanation': expCtrl.text.trim().isEmpty
                                ? null : expCtrl.text.trim(),
                            'points': 10,
                          };
                          setState(() {
                            if (index != null) {
                              _questions[index] = newQ;
                            } else {
                              _questions.add(newQ);
                            }
                          });
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _questionLabel(String type) {
    switch (type) {
      case 'fill_blank':       return 'Câu có chỗ trống (dùng ___)';
      case 'mcq':              return 'Nội dung câu hỏi';
      case 'true_false':       return 'Phát biểu (True/False)';
      case 'sentence_rewrite': return 'Từ gợi ý (VD: i / go / school)';
      case 'writing_prompt':   return 'Đề bài viết';
      default:                 return 'Nội dung câu hỏi';
    }
  }

  String _answerLabel(String type) {
    switch (type) {
      case 'fill_blank':       return 'Đáp án đúng';
      case 'true_false':       return 'Đáp án đúng (True / False)';
      case 'sentence_rewrite': return 'Câu đúng (VD: I am going to school)';
      case 'writing_prompt':   return 'Đáp án mẫu (tùy chọn)';
      default:                 return 'Đáp án đúng';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final skillColor = _skillColor(_skill);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa bài học' : 'Thêm bài học mới'),
        backgroundColor: skillColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : const Text('LƯU',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Skill selector ──────────────────────────────────────────
            _SectionHeader(icon: Icons.category_outlined, label: 'Kỹ năng & Trình độ'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: _skill,
                decoration: const InputDecoration(
                    labelText: 'Kỹ năng *', border: OutlineInputBorder()),
                items: [
                  _skillDropItem('reading',   Icons.chrome_reader_mode_rounded, 'Đọc'),
                  _skillDropItem('listening', Icons.headphones_rounded,         'Nghe'),
                  _skillDropItem('grammar',   Icons.edit_note_rounded,          'Ngữ pháp'),
                  _skillDropItem('writing',   Icons.edit_rounded,               'Viết'),
                ],
                onChanged: (v) => setState(() {
                  _skill = v!;
                  if (!_isEdit) _questions.clear();
                }),
              )),
              const SizedBox(width: 12),
              Expanded(child: DropdownButtonFormField<String>(
                value: _level,
                decoration: const InputDecoration(
                    labelText: 'Trình độ *', border: OutlineInputBorder()),
                items: ['A1','A2','B1','B2','C1','C2']
                    .map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => setState(() => _level = v!),
              )),
            ]),
            const SizedBox(height: 16),

            // ← THÊM: Dropdown chọn thì — chỉ hiện khi skill == grammar ──
            if (_skill == 'grammar') ...[
              _SectionHeader(
                icon: Icons.format_list_bulleted_rounded,
                label: 'Thì ngữ pháp',
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _grammarTopic,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Chọn thì *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school_rounded,
                      color: AppTheme.skillGrammar),
                ),
                items: _grammarTenses.map((t) => DropdownMenuItem(
                  value: t.$1,
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: t.$1,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.black87),
                        ),
                        TextSpan(
                          text: '  ${t.$2}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.skillGrammar),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
                onChanged: (v) => setState(() => _grammarTopic = v!),
              ),
              const SizedBox(height: 16),
            ],
            // ─────────────────────────────────────────────────────────────

            // ── Thông tin cơ bản ────────────────────────────────────────
            _SectionHeader(icon: Icons.info_outline_rounded, label: 'Thông tin bài học'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Tiêu đề bài học *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title_rounded)),
              validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                  labelText: 'Mô tả ngắn',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.short_text_rounded)),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // ── Audio (chỉ listening) ───────────────────────────────────
            if (_skill == 'listening') ...[
              _SectionHeader(icon: Icons.audio_file_rounded, label: 'File Audio *'),
              const SizedBox(height: 10),
              _audioLocalPath == null
                  ? InkWell(
                onTap: _picking ? null : _pickAudio,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppTheme.skillListening, width: 2),
                    borderRadius: BorderRadius.circular(14),
                    color: AppTheme.skillListening.withValues(alpha: 0.05),
                  ),
                  child: _picking
                      ? const Column(children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Đang copy file...'),
                  ])
                      : Column(children: [
                    const Icon(Icons.audio_file_rounded,
                        size: 48, color: AppTheme.skillListening),
                    const SizedBox(height: 8),
                    const Text('Nhấn để chọn file audio',
                        style: TextStyle(fontWeight: FontWeight.w600,
                            color: AppTheme.skillListening)),
                    const SizedBox(height: 4),
                    const Text('Hỗ trợ: mp3, wav, m4a, aac',
                        style: TextStyle(color: Colors.grey,
                            fontSize: 12)),
                  ]),
                ),
              )
                  : Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(children: [
                  const Icon(Icons.audio_file_rounded,
                      color: Colors.green, size: 36),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_audioFileName ?? 'Audio file',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (_audioSizeKb != null)
                        Text('${_audioSizeKb}KB',
                            style: TextStyle(color: Colors.grey.shade600,
                                fontSize: 12)),
                      const Text('✅ Đã lưu vào bộ nhớ app',
                          style: TextStyle(color: Colors.green, fontSize: 12)),
                    ],
                  )),
                  Column(children: [
                    IconButton(icon: const Icon(Icons.swap_horiz_rounded,
                        color: AppTheme.primary),
                        onPressed: _pickAudio, tooltip: 'Đổi file'),
                    IconButton(icon: Icon(Icons.delete_outline_rounded,
                        color: Colors.red.shade400),
                        onPressed: () => setState(() {
                          _audioLocalPath = null;
                          _audioFileName = null;
                          _audioSizeKb = null;
                        }), tooltip: 'Xóa'),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // ── Nội dung / Script ───────────────────────────────────────
            _SectionHeader(
              icon: _skill == 'listening' ? Icons.subtitles_outlined
                  : Icons.article_outlined,
              label: _skill == 'listening' ? 'Script bài nghe (hiện sau nộp bài)'
                  : _skill == 'writing'    ? 'Đề bài / Hướng dẫn'
                  : _skill == 'grammar'    ? 'Lý thuyết bổ sung (tùy chọn)'
                  : 'Nội dung bài đọc *',
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _contentCtrl,
              decoration: InputDecoration(
                hintText: _contentHint(_skill),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: _skill == 'writing' ? 6 : 8,
              validator: (v) =>
              (_skill == 'reading' && v!.trim().isEmpty) ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 20),

            // ── Câu hỏi ─────────────────────────────────────────────────
            Row(children: [
              Expanded(child: _SectionHeader(
                icon: Icons.quiz_outlined,
                label: 'Câu hỏi / Bài tập (${_questions.length})',
              )),
              TextButton.icon(
                onPressed: () => _openQuestionDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Thêm câu hỏi'),
                style: TextButton.styleFrom(
                    foregroundColor: skillColor),
              ),
            ]),
            const SizedBox(height: 8),

            _skillHint(_skill),
            const SizedBox(height: 8),

            if (_questions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(child: Text('Chưa có câu hỏi nào',
                    style: TextStyle(color: Colors.grey))),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                onReorder: (oldIdx, newIdx) {
                  setState(() {
                    if (newIdx > oldIdx) newIdx--;
                    final item = _questions.removeAt(oldIdx);
                    _questions.insert(newIdx, item);
                  });
                },
                itemBuilder: (_, i) {
                  final q = _questions[i];
                  return _QuestionTile(
                    key: ValueKey(i),
                    index: i,
                    question: q,
                    skillColor: skillColor,
                    onEdit: () => _openQuestionDialog(existing: q, index: i),
                    onDelete: () => setState(() => _questions.removeAt(i)),
                  );
                },
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Color _skillColor(String skill) {
    switch (skill) {
      case 'reading':   return AppTheme.skillReading;
      case 'listening': return AppTheme.skillListening;
      case 'grammar':   return AppTheme.skillGrammar;
      case 'writing':   return const Color(0xFF6A1B9A);
      default:          return AppTheme.primary;
    }
  }

  DropdownMenuItem<String> _skillDropItem(
      String value, IconData icon, String label) {
    return DropdownMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 18, color: _skillColor(value)),
        const SizedBox(width: 8),
        Text(label),
      ]),
    );
  }

  String _contentHint(String skill) {
    switch (skill) {
      case 'listening': return 'Nhập transcript/script bài nghe...';
      case 'writing':   return 'Nhập đề bài, yêu cầu viết, tiêu chí chấm điểm...';
      case 'grammar':   return 'Ghi chú lý thuyết bổ sung (tùy chọn)...';
      default:          return 'Nhập đoạn văn bài đọc...';
    }
  }

  Widget _skillHint(String skill) {
    switch (skill) {
      case 'listening':
        return _HintBox(color: Colors.teal,
            text: '📢 Thêm câu hỏi điền từ (fill_blank) hoặc trắc nghiệm cho bài nghe');
      case 'grammar':
        return _HintBox(color: Colors.purple,
            text: '📚 Grammar: Điền từ, Trắc nghiệm, hoặc Viết câu đúng (sentence_rewrite)\nVD: i / go → I am going');
      case 'writing':
        return _HintBox(color: Colors.deepOrange,
            text: '✍️ Writing: Thêm đề bài (writing_prompt) hoặc bài điền từ');
      default:
        return _HintBox(color: Colors.blue,
            text: '📖 Reading: Trắc nghiệm, điền từ hoặc đúng/sai dựa trên nội dung bài đọc');
    }
  }
}

// ── Widget con ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: Colors.grey.shade600),
    const SizedBox(width: 6),
    Text(label, style: TextStyle(
        fontWeight: FontWeight.w600, fontSize: 14,
        color: Colors.grey.shade700)),
    const SizedBox(width: 8),
    Flexible(child: Divider(color: Colors.grey.shade300)),
  ]);
}

class _HintBox extends StatelessWidget {
  final Color color;
  final String text;
  const _HintBox({required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(text,
        style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8))),
  );
}

class _QuestionTile extends StatelessWidget {
  final int index;
  final Map<String, dynamic> question;
  final Color skillColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _QuestionTile({
    super.key, required this.index, required this.question,
    required this.skillColor, required this.onEdit, required this.onDelete,
  });

  String _typeLabel(String type) {
    switch (type) {
      case 'fill_blank':       return '📝 Điền từ';
      case 'mcq':              return '🔤 Trắc nghiệm';
      case 'true_false':       return '✅ Đúng/Sai';
      case 'sentence_rewrite': return '🔄 Viết câu';
      case 'writing_prompt':   return '✍️ Đề bài';
      default:                 return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Icon(Icons.drag_handle_rounded, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 14,
            backgroundColor: skillColor.withValues(alpha: 0.15),
            child: Text('${index + 1}',
                style: TextStyle(color: skillColor, fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(question['question'] as String,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500,
                      fontSize: 13)),
              const SizedBox(height: 3),
              Row(children: [
                Text(_typeLabel(question['type'] as String),
                    style: TextStyle(fontSize: 11, color: skillColor)),
                const Text(' · ', style: TextStyle(color: Colors.grey)),
                Expanded(child: Text(
                  'Đáp án: ${question['correct'] ?? '(chưa đặt)'}',
                  style: TextStyle(fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                )),
              ]),
            ],
          )),
          IconButton(icon: const Icon(Icons.edit_outlined,
              color: AppTheme.primary, size: 18), onPressed: onEdit),
          IconButton(icon: Icon(Icons.delete_outline_rounded,
              color: Colors.red.shade400, size: 18), onPressed: onDelete),
        ]),
      ),
    );
  }
}