// lib/features/reading/reading_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/lesson_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class ReadingListScreen extends StatefulWidget {
  const ReadingListScreen({super.key});
  @override
  State<ReadingListScreen> createState() => _ReadingListScreenState();
}

class _ReadingListScreenState extends State<ReadingListScreen> {
  String _level = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Chỉ load lại nếu chưa load
      final lp = context.read<LessonProvider>();
      if (!lp.initialLoaded) lp.loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lp   = context.watch<LessonProvider>();
    final auth = context.watch<AuthProvider>();
    final lessons = lp.getBySkill('reading').where((l) =>
        _level.isEmpty || l.level == _level).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Luyện đọc'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Lọc trình độ',
            onSelected: (v) => setState(() => _level = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: '', child: Text('Tất cả trình độ')),
              ...['A1','A2','B1','B2','C1','C2'].map((l) =>
                  PopupMenuItem(value: l, child: Text('Trình độ $l'))),
            ],
          ),
        ],
      ),
      body: !auth.isLoggedIn
          ? _LoginPrompt(skill: 'đọc')
          : lp.isLoading
              ? const Center(child: CircularProgressIndicator())
              : lessons.isEmpty
                  ? _EmptyState(icon: Icons.chrome_reader_mode_outlined,
                      label: 'Chưa có bài đọc nào')
                  : RefreshIndicator(
                      onRefresh: () => lp.loadAll(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: lessons.length,
                        itemBuilder: (_, i) => _LessonCard(
                          lesson: lessons[i],
                          color: AppTheme.skillReading,
                          icon: Icons.chrome_reader_mode_rounded,
                          onTap: () => Navigator.pushNamed(
                              context, '/reading/detail',
                              arguments: lessons[i]),
                        ),
                      ),
                    ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _LessonCard extends StatelessWidget {
  final LessonModel lesson;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _LessonCard({required this.lesson, required this.color,
      required this.icon, required this.onTap});

  static const _levelColors = {
    'A1': AppTheme.levelA1, 'A2': AppTheme.levelA2,
    'B1': AppTheme.levelB1, 'B2': AppTheme.levelB2,
    'C1': AppTheme.levelC1, 'C2': AppTheme.levelC2,
  };

  @override
  Widget build(BuildContext context) {
    final lvlColor = _levelColors[lesson.level] ?? AppTheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(lesson.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: lvlColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(lesson.level,
                        style: TextStyle(color: lvlColor, fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
                if (lesson.description != null && lesson.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(lesson.description!,
                      style: TextStyle(color: Colors.grey.shade600,
                          fontSize: 13),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            )),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  final String skill;
  const _LoginPrompt({required this.skill});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock_outline_rounded, size: 72, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text('Đăng nhập để luyện $skill',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          child: const Text('Đăng nhập ngay'),
        ),
      ]),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 72, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text(label, style: const TextStyle(
          fontWeight: FontWeight.w500, fontSize: 16)),
      const SizedBox(height: 4),
      Text('Admin sẽ thêm bài học sớm!',
          style: TextStyle(color: Colors.grey.shade500)),
    ]),
  );
}
