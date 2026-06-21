// lib/features/admin/admin_lesson_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/lesson_provider.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class AdminLessonListScreen extends StatefulWidget {
  const AdminLessonListScreen({super.key});
  @override
  State<AdminLessonListScreen> createState() => _AdminLessonListScreenState();
}

class _AdminLessonListScreenState extends State<AdminLessonListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _search = '';

  static const _skills = ['reading', 'listening', 'grammar', 'writing'];
  static const _skillLabels = ['Đọc', 'Nghe', 'Ngữ pháp', 'Viết'];
  static const _skillColors = {
    'reading':   AppTheme.skillReading,
    'listening': AppTheme.skillListening,
    'grammar':   AppTheme.skillGrammar,
    'writing':   Color(0xFF6A1B9A),
  };
  static const _skillIcons = {
    'reading':   Icons.chrome_reader_mode_rounded,
    'listening': Icons.headphones_rounded,
    'grammar':   Icons.edit_note_rounded,
    'writing':   Icons.edit_rounded,
  };

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _skills.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadAllForAdmin();
    });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LessonProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý bài học'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: List.generate(_skills.length, (i) {
            final count = lp.getBySkill(_skills[i]).where((l) =>
                _search.isEmpty ||
                l.title.toLowerCase().contains(_search.toLowerCase())).length;
            return Tab(text: '${_skillLabels[i]} ($count)');
          }),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade700,
        onPressed: () {
          // Pass current tab skill as default
          final skill = _skills[_tab.index];
          Navigator.pushNamed(context, '/admin/lesson',
              arguments: {'defaultSkill': skill}).then((_) =>
              context.read<LessonProvider>().loadAllForAdmin());
        },
        icon: const Icon(Icons.add_rounded),
        label: Text('Thêm ${_skillLabels[_tab.index]}'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Tìm bài học...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _search = ''))
                  : null,
            ),
          ),
        ),
        Expanded(
          child: lp.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tab,
                  children: _skills.map((skill) {
                    final lessons = lp.getBySkill(skill).where((l) =>
                        _search.isEmpty ||
                        l.title.toLowerCase().contains(
                            _search.toLowerCase())).toList();
                    return _LessonTab(
                      lessons: lessons,
                      skill: skill,
                      color: _skillColors[skill] ?? AppTheme.primary,
                      icon: _skillIcons[skill] ?? Icons.book_rounded,
                      onReload: () => lp.loadAllForAdmin(),
                    );
                  }).toList(),
                ),
        ),
      ]),
    );
  }
}

// ── Tab danh sách bài học theo skill ─────────────────────────────────────────

class _LessonTab extends StatelessWidget {
  final List<LessonModel> lessons;
  final String skill;
  final Color color;
  final IconData icon;
  final VoidCallback onReload;
  const _LessonTab({required this.lessons, required this.skill,
      required this.color, required this.icon, required this.onReload});

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('Chưa có bài $skill nào',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
        const SizedBox(height: 8),
        Text('Nhấn nút + để thêm bài học mới',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      itemCount: lessons.length,
      itemBuilder: (ctx, i) {
        final l = lessons[i];
        return _LessonAdminCard(
            lesson: l, skill: skill, color: color, icon: icon,
            onReload: onReload);
      },
    );
  }
}

class _LessonAdminCard extends StatelessWidget {
  final LessonModel lesson;
  final String skill;
  final Color color;
  final IconData icon;
  final VoidCallback onReload;
  const _LessonAdminCard({required this.lesson, required this.skill,
      required this.color, required this.icon, required this.onReload});

  static const _levelColors = {
    'A1': AppTheme.levelA1, 'A2': AppTheme.levelA2,
    'B1': AppTheme.levelB1, 'B2': AppTheme.levelB2,
    'C1': AppTheme.levelC1, 'C2': AppTheme.levelC2,
  };

  @override
  Widget build(BuildContext context) {
    final lvlColor = _levelColors[lesson.level] ?? AppTheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lesson.title,
                  style: const TextStyle(fontWeight: FontWeight.w600,
                      fontSize: 14),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: lvlColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(lesson.level,
                      style: TextStyle(fontSize: 11, color: lvlColor,
                          fontWeight: FontWeight.bold)),
                ),
                if (skill == 'listening' && lesson.audioUrl != null) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.audio_file_rounded,
                      size: 14, color: AppTheme.skillListening),
                  const Text(' Audio', style: TextStyle(
                      fontSize: 11, color: AppTheme.skillListening)),
                ],
                if (lesson.description != null && lesson.description!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Expanded(child: Text(lesson.description!,
                      style: TextStyle(fontSize: 12,
                          color: Colors.grey.shade600),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ]),
            ],
          )),
          Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              icon: Icon(Icons.edit_outlined, color: color, size: 20),
              tooltip: 'Sửa',
              onPressed: () => Navigator.pushNamed(context, '/admin/lesson',
                  arguments: lesson).then((_) => onReload()),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  color: Colors.red.shade400, size: 20),
              tooltip: 'Xóa',
              onPressed: () => _confirmDelete(context, lesson),
            ),
          ]),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, LessonModel l) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Xóa bài học?'),
        ]),
        content: Text('Xóa "${l.title}"?\nTất cả câu hỏi liên quan cũng bị xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ctx.read<LessonProvider>().deleteLesson(l.id!);
              onReload();
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                  content: Text('Đã xóa bài học'),
                  backgroundColor: Colors.green,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
