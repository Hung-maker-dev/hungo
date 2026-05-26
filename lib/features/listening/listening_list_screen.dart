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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadLessons(skill: 'listening');
    });
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LessonProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Luyện nghe')),
      body: !auth.isLoggedIn
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.lock_outline_rounded, size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('Đăng nhập để luyện nghe',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    child: const Text('Đăng nhập'),
                  ),
                ]),
              ),
            )
          : lp.isLoading
              ? const Center(child: CircularProgressIndicator())
              : lp.lessons.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.headphones_outlined, size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text('Chưa có bài nghe'),
                        Text('Admin sẽ thêm bài sớm!',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ]),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: lp.lessons.length,
                      itemBuilder: (_, i) {
                        final l = lp.lessons[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.pushNamed(context, '/listening/exercise', arguments: l),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(children: [
                                Container(
                                  width: 52, height: 52,
                                  decoration: BoxDecoration(
                                    color: AppTheme.skillListening.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.headphones_rounded,
                                      color: AppTheme.skillListening, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(l.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    if (l.description != null)
                                      Text(l.description!,
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                          maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.levelA1.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(l.level,
                                          style: const TextStyle(color: AppTheme.levelA1,
                                              fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ]),
                                ),
                                const Icon(Icons.play_circle_filled_rounded,
                                    color: AppTheme.skillListening, size: 32),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
