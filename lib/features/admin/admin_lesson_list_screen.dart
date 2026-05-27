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

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadLessons();
    });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LessonProvider>();
    final all = lp.lessons.where((l) =>
        _search.isEmpty ||
        l.title.toLowerCase().contains(_search.toLowerCase())).toList();

    final reading  = all.where((l) => l.skill == 'reading').toList();
    final listening = all.where((l) => l.skill == 'listening').toList();
    final grammar  = all.where((l) => l.skill == 'grammar').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý bài học'),
        backgroundColor: Colors.red.shade700,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Đọc (${reading.length})'),
            Tab(text: 'Nghe (${listening.length})'),
            Tab(text: 'Ngữ pháp (${grammar.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red.shade700,
        onPressed: () => Navigator.pushNamed(context, '/admin/lesson',
            arguments: null).then((_) =>
            context.read<LessonProvider>().loadLessons()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm bài'),
      ),
      body: Column(children: [
        // Search bar
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
                  children: [
                    _LessonListTab(lessons: reading,  skill: 'reading'),
                    _LessonListTab(lessons: listening, skill: 'listening'),
                    _LessonListTab(lessons: grammar,  skill: 'grammar'),
                  ],
                ),
        ),
      ]),
    );
  }
}

class _LessonListTab extends StatelessWidget {
  final List<LessonModel> lessons;
  final String skill;
  const _LessonListTab({required this.lessons, required this.skill});

  static const _skillColors = {
    'reading':   AppTheme.skillReading,
    'listening': AppTheme.skillListening,
    'grammar':   AppTheme.skillGrammar,
  };
  static const _skillIcons = {
    'reading':   Icons.chrome_reader_mode_rounded,
    'listening': Icons.headphones_rounded,
    'grammar':   Icons.edit_note_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = _skillColors[skill] ?? AppTheme.primary;
    final icon  = _skillIcons[skill]  ?? Icons.book_rounded;

    if (lessons.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('Chưa có bài $skill nào',
            style: TextStyle(color: Colors.grey.shade500)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
      itemCount: lessons.length,
      itemBuilder: (ctx, i) {
        final l = lessons[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            title: Text(l.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 6, top: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(l.level,
                    style: TextStyle(fontSize: 11, color: color,
                        fontWeight: FontWeight.bold)),
              ),
              if (l.description != null)
                Expanded(child: Text(l.description!,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12))),
            ]),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              // Edit
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppTheme.primary, size: 22),
                tooltip: 'Sửa',
                onPressed: () => Navigator.pushNamed(ctx, '/admin/lesson',
                    arguments: l).then((_) =>
                    ctx.read<LessonProvider>().loadLessons()),
              ),
              // Delete
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: Colors.red.shade400, size: 22),
                tooltip: 'Xóa',
                onPressed: () => _confirmDelete(ctx, l),
              ),
            ]),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext ctx, LessonModel l) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Xóa bài học?'),
        content: Text('Xóa "${l.title}"? Tất cả câu hỏi liên quan cũng bị xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ctx.read<LessonProvider>().deleteLesson(l.id!);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                  content: Text('Đã xóa bài học'),
                  backgroundColor: Colors.green,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
