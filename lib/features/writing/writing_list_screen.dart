// lib/features/writing/writing_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/lesson_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/models.dart';

class WritingListScreen extends StatefulWidget {
  const WritingListScreen({super.key});
  @override
  State<WritingListScreen> createState() => _WritingListScreenState();
}

class _WritingListScreenState extends State<WritingListScreen> {
  static const _color = Color(0xFF6A1B9A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadLessons(skill: 'writing');
    });
  }

  @override
  Widget build(BuildContext context) {
    final lp   = context.watch<LessonProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Luyện viết')),
      body: !auth.isLoggedIn
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_outline_rounded, size: 72, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Đăng nhập để luyện viết',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Đăng nhập'),
              ),
            ]))
          : lp.isLoading
              ? const Center(child: CircularProgressIndicator())
              : lp.lessons.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.edit_off_outlined, size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('Chưa có bài viết nào'),
                      Text('Admin sẽ thêm bài học sớm!',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ]))
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
                            onTap: () => Navigator.pushNamed(context, '/writing/exercise', arguments: l),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(children: [
                                Container(
                                  width: 52, height: 52,
                                  decoration: BoxDecoration(
                                    color: _color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.edit_rounded, color: _color, size: 28),
                                ),
                                const SizedBox(width: 14),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(l.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  if (l.description != null)
                                    Text(l.description!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                        maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(l.level, style: const TextStyle(
                                        fontSize: 11, fontWeight: FontWeight.bold, color: _color)),
                                  ),
                                ])),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
