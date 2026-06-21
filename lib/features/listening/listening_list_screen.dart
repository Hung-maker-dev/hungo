// lib/features/listening/listening_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/lesson_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class ListeningListScreen extends StatefulWidget {
  const ListeningListScreen({super.key});
  @override
  State<ListeningListScreen> createState() => _ListeningListScreenState();
}

class _ListeningListScreenState extends State<ListeningListScreen> {
  String _level = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lp = context.read<LessonProvider>();
      if (!lp.initialLoaded) lp.loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lp   = context.watch<LessonProvider>();
    final auth = context.watch<AuthProvider>();
    final lessons = lp.getBySkill('listening').where((l) =>
        _level.isEmpty || l.level == _level).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Luyện nghe'),
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
          ? _LoginPrompt()
          : lp.isLoading
              ? const Center(child: CircularProgressIndicator())
              : lessons.isEmpty
                  ? _EmptyListening()
                  : RefreshIndicator(
                      onRefresh: () => lp.loadAll(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: lessons.length,
                        itemBuilder: (_, i) => _ListeningCard(
                          lesson: lessons[i],
                          onTap: () => Navigator.pushNamed(context,
                              '/listening/exercise', arguments: lessons[i]),
                        ),
                      ),
                    ),
    );
  }
}

class _ListeningCard extends StatelessWidget {
  final LessonModel lesson;
  final VoidCallback onTap;
  const _ListeningCard({required this.lesson, required this.onTap});

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
                color: AppTheme.skillListening.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.headphones_rounded,
                  color: AppTheme.skillListening, size: 28),
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
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.audio_file_rounded,
                      size: 14, color: AppTheme.skillListening),
                  const SizedBox(width: 4),
                  const Text('Bài nghe',
                      style: TextStyle(color: AppTheme.skillListening,
                          fontSize: 12)),
                  if (lesson.description != null && lesson.description!.isNotEmpty) ...[
                    const Text(' · ', style: TextStyle(color: Colors.grey)),
                    Expanded(child: Text(lesson.description!,
                        style: TextStyle(color: Colors.grey.shade600,
                            fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ]),
              ],
            )),
            const SizedBox(width: 8),
            const Icon(Icons.play_circle_outline_rounded,
                size: 28, color: AppTheme.skillListening),
          ]),
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock_outline_rounded, size: 72, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        const Text('Đăng nhập để luyện nghe',
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

class _EmptyListening extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.headphones_outlined, size: 72, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      const Text('Chưa có bài nghe nào',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
      const SizedBox(height: 4),
      Text('Admin sẽ thêm bài học sớm!',
          style: TextStyle(color: Colors.grey.shade500)),
    ]),
  );
}
