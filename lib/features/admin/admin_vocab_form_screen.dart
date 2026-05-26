// lib/features/admin/admin_vocab_form_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_theme.dart';
import 'package:sqflite/sqflite.dart';


class AdminVocabFormScreen extends StatefulWidget {
  const AdminVocabFormScreen({super.key});
  @override
  State<AdminVocabFormScreen> createState() => _AdminVocabFormScreenState();
}

class _AdminVocabFormScreenState extends State<AdminVocabFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wordCtrl = TextEditingController();
  final _phoneticCtrl = TextEditingController();
  final _posCtrl = TextEditingController();
  final _defCtrl = TextEditingController();
  final _defViCtrl = TextEditingController();
  final _exCtrl = TextEditingController();
  String _level = 'A1';
  String _topic = '';
  bool _saving = false;

  final _topics = ['', 'travel', 'food', 'business', 'technology',
      'health', 'education', 'sports', 'nature', 'daily life'];

  @override
  void dispose() {
    _wordCtrl.dispose(); _phoneticCtrl.dispose(); _posCtrl.dispose();
    _defCtrl.dispose(); _defViCtrl.dispose(); _exCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();

    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('vocabulary', {
        'word': _wordCtrl.text.trim().toLowerCase(),
        'phonetic': _phoneticCtrl.text.trim().isEmpty ? null : _phoneticCtrl.text.trim(),
        'part_of_speech': _posCtrl.text.trim().isEmpty ? null : _posCtrl.text.trim(),
        'definition': _defCtrl.text.trim(),
        'definition_vi': _defViCtrl.text.trim().isEmpty ? null : _defViCtrl.text.trim(),
        'example': _exCtrl.text.trim().isEmpty ? null : _exCtrl.text.trim(),
        'level': _level,
        'topic': _topic.isEmpty ? null : _topic,
        'created_by': auth.currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Thêm từ vựng thành công!'),
          backgroundColor: Colors.green,
        ));
        _formKey.currentState!.reset();
        _wordCtrl.clear(); _phoneticCtrl.clear(); _posCtrl.clear();
        _defCtrl.clear(); _defViCtrl.clear(); _exCtrl.clear();
        setState(() { _level = 'A1'; _topic = ''; });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm từ vựng'),
        backgroundColor: Colors.red.shade700,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Lưu',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Word
            TextFormField(
              controller: _wordCtrl,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                labelText: 'Từ tiếng Anh *',
                prefixIcon: Icon(Icons.text_fields_rounded),
                hintText: 'vd: beautiful',
              ),
              validator: (v) => v!.trim().isEmpty ? 'Bắt buộc nhập từ' : null,
            ),
            const SizedBox(height: 12),

            // Phonetic
            TextFormField(
              controller: _phoneticCtrl,
              decoration: const InputDecoration(
                labelText: 'Phiên âm',
                prefixIcon: Icon(Icons.record_voice_over_outlined),
                hintText: 'vd: /ˈbjuː.tɪ.fəl/',
              ),
            ),
            const SizedBox(height: 12),

            // Part of speech
            TextFormField(
              controller: _posCtrl,
              decoration: const InputDecoration(
                labelText: 'Từ loại',
                prefixIcon: Icon(Icons.category_outlined),
                hintText: 'adjective / noun / verb / adverb...',
              ),
            ),
            const SizedBox(height: 12),

            // Level + Topic row
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _level,
                  decoration: const InputDecoration(labelText: 'Trình độ'),
                  items: ['A1','A2','B1','B2','C1','C2'].map((l) =>
                      DropdownMenuItem(value: l, child: Text(l))).toList(),
                  onChanged: (v) => setState(() => _level = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _topic,
                  decoration: const InputDecoration(labelText: 'Chủ đề'),
                  items: _topics.map((t) =>
                      DropdownMenuItem(value: t,
                          child: Text(t.isEmpty ? 'Không có' : t))).toList(),
                  onChanged: (v) => setState(() => _topic = v!),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // Definition EN
            TextFormField(
              controller: _defCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Định nghĩa tiếng Anh *',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
                hintText: 'vd: pleasing the senses or mind aesthetically',
              ),
              validator: (v) => v!.trim().isEmpty ? 'Bắt buộc nhập định nghĩa' : null,
            ),
            const SizedBox(height: 12),

            // Definition VI
            TextFormField(
              controller: _defViCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Nghĩa tiếng Việt',
                prefixIcon: Icon(Icons.translate_rounded),
                hintText: 'vd: đẹp, xinh đẹp',
              ),
            ),
            const SizedBox(height: 12),

            // Example
            TextFormField(
              controller: _exCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Câu ví dụ',
                prefixIcon: Icon(Icons.format_quote_rounded),
                hintText: 'vd: She has a beautiful smile.',
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded),
                label: const Text('Lưu từ vựng'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red.shade700,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
