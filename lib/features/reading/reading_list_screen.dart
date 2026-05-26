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
      context.read<LessonProvider>().loadLessons(skill: 'reading');
    });
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LessonProvider>();
    final auth = context.watch<AuthProvider>();

    final lessons = lp.lessons.where((l) =>
        _level.isEmpty || l.level == _level).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Luyện đọc'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (v) => setState(() => _level = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: '', child: Text('Tất cả')),
              ...['A1','A2','B1','B2','C1'].map((l) =>
                  PopupMenuItem(value: l, child: Text('Trình độ $l'))),
            ],
          ),
        ],
      ),
      body: !auth.isLoggedIn
          ? _LoginPrompt()
          : lp.isLoading
              ? const Center(child: CircularProgressIndicator())
              : lessons.isEmpty
                  ? _EmptyLessons()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: lessons.length,
                      itemBuilder: (_, i) => _LessonCard(
                        lesson: lessons[i],
                        onTap: () => Navigator.pushNamed(
                          context, '/reading/detail', arguments: lessons[i]),
                      ),
                    ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final LessonModel lesson;
  final VoidCallback onTap;
  const _LessonCard({required this.lesson, required this.onTap});

  static const _levelColors = {
    'A1': AppTheme.levelA1, 'A2': AppTheme.levelA2,
    'B1': AppTheme.levelB1, 'B2': AppTheme.levelB2,
    'C1': AppTheme.levelC1, 'C2': AppTheme.levelC2,
  };

  @override
  Widget build(BuildContext context) {
    final color = _levelColors[lesson.level] ?? AppTheme.primary;
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
                color: AppTheme.skillReading.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.chrome_reader_mode_rounded,
                  color: AppTheme.skillReading, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(lesson.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(lesson.level,
                        style: TextStyle(color: color, fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
                if (lesson.description != null) ...[
                  const SizedBox(height: 4),
                  Text(lesson.description!,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ]),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock_outline_rounded, size: 72, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        const Text('Đăng nhập để luyện đọc',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          child: const Text('Đăng nhập ngay'),
        ),
      ]),
    ),
  );
}

class _EmptyLessons extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.chrome_reader_mode_outlined, size: 72, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      const Text('Chưa có bài đọc nào'),
      const SizedBox(height: 4),
      Text('Admin sẽ thêm bài học sớm!',
          style: TextStyle(color: Colors.grey.shade600)),
    ]),
  );
}
