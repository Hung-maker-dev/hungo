// lib/features/writing/writing_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/lesson_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/submission_provider.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class WritingListScreen extends StatefulWidget {
  const WritingListScreen({super.key});
  @override
  State<WritingListScreen> createState() => _WritingListScreenState();
}

class _WritingListScreenState extends State<WritingListScreen> {
  static const _color = Color(0xFF6A1B9A);
  String _level = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lp   = context.read<LessonProvider>();
      final auth = context.read<AuthProvider>();
      if (!lp.initialLoaded) lp.loadAll();
      // Load số bài chờ chấm để hiện badge
      if (auth.isLoggedIn) {
        context.read<SubmissionProvider>()
            .loadMySubmissions(auth.currentUser!.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lp   = context.watch<LessonProvider>();
    final auth = context.watch<AuthProvider>();
    final sp   = context.watch<SubmissionProvider>();
    final lessons = lp.getBySkill('writing').where((l) =>
    _level.isEmpty || l.level == _level).toList();

    // Đếm bài đã chấm và đang chờ để hiện trên banner
    final pendingCount = sp.mySubmissions
        .where((s) => s.status == 'pending').length;
    final gradedCount  = sp.mySubmissions
        .where((s) => s.status == 'graded').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Luyện viết'),
        actions: [
          // Nút xem bài của tôi (có badge số bài chờ chấm)
          if (auth.isLoggedIn)
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.assignment_turned_in_outlined),
                  tooltip: 'Bài viết của tôi',
                  onPressed: () => Navigator.pushNamed(
                      context, '/my-submissions'),
                ),
                if (pendingCount > 0)
                  Positioned(
                    top: 6, right: 6,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Lọc trình độ',
            onSelected: (v) => setState(() => _level = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: '', child: Text('Tất cả trình độ')),
              ...['A1', 'A2', 'B1', 'B2', 'C1', 'C2'].map((l) =>
                  PopupMenuItem(value: l, child: Text('Trình độ $l'))),
            ],
          ),
        ],
      ),
      body: !auth.isLoggedIn
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock_outline_rounded,
                size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('Đăng nhập để luyện viết',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/login'),
              child: const Text('Đăng nhập ngay'),
            ),
          ]),
        ),
      )
          : lp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : lessons.isEmpty
          ? Center(
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_off_outlined,
                  size: 72, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text('Chưa có bài viết nào',
                  style: TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 16)),
              Text('Admin sẽ thêm bài học sớm!',
                  style:
                  TextStyle(color: Colors.grey.shade500)),
            ]),
      )
          : RefreshIndicator(
        onRefresh: () async {
          await lp.loadAll();
          if (auth.isLoggedIn) {
            await sp.loadMySubmissions(
                auth.currentUser!.id!);
          }
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lessons.length + 1, // +1 cho banner
          itemBuilder: (_, i) {
            // Index 0: banner tóm tắt bài đã nộp
            if (i == 0) {
              return _SubmissionBanner(
                pendingCount: pendingCount,
                gradedCount:  gradedCount,
                color:        _color,
                onTap: () => Navigator.pushNamed(
                    context, '/my-submissions'),
              );
            }
            final l = lessons[i - 1];
            return _WritingCard(
              lesson: l,
              color:  _color,
              onTap:  () => Navigator.pushNamed(
                  context, '/writing/exercise',
                  arguments: l),
            );
          },
        ),
      ),
    );
  }
}

// ── Banner tóm tắt bài đã nộp ────────────────────────────────────────────────
class _SubmissionBanner extends StatelessWidget {
  final int pendingCount;
  final int gradedCount;
  final Color color;
  final VoidCallback onTap;

  const _SubmissionBanner({
    required this.pendingCount,
    required this.gradedCount,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = pendingCount + gradedCount;
    if (total == 0) return const SizedBox(height: 4);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          const Icon(Icons.assignment_turned_in_outlined,
              color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bài viết của tôi',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Row(children: [
                    if (pendingCount > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$pendingCount đang chấm',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (gradedCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$gradedCount đã chấm',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                  ]),
                ]),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white70, size: 14),
        ]),
      ),
    );
  }
}

// ── Card bài học ──────────────────────────────────────────────────────────────
class _WritingCard extends StatelessWidget {
  final LessonModel lesson;
  final Color color;
  final VoidCallback onTap;
  const _WritingCard(
      {required this.lesson, required this.color, required this.onTap});

  static const _levelColors = {
    'A1': AppTheme.levelA1, 'A2': AppTheme.levelA2,
    'B1': AppTheme.levelB1, 'B2': AppTheme.levelB2,
    'C1': AppTheme.levelC1, 'C2': AppTheme.levelC2,
  };

  String _typeLabel(LessonModel l) {
    if (l.description?.toLowerCase().contains('email') == true)
      return '📧 Viết email';
    if (l.description?.toLowerCase().contains('essay') == true ||
        l.description?.toLowerCase().contains('luận') == true)
      return '📝 Viết luận';
    if (l.description?.toLowerCase().contains('paragraph') == true ||
        l.description?.toLowerCase().contains('đoạn') == true)
      return '📄 Viết đoạn văn';
    return '✍️ Bài viết';
  }

  @override
  Widget build(BuildContext context) {
    final lvlColor = _levelColors[lesson.level] ?? color;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.edit_rounded, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(lesson.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: lvlColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(lesson.level,
                            style: TextStyle(
                                color: lvlColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(_typeLabel(lesson),
                        style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w500)),
                    if (lesson.description != null &&
                        lesson.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(lesson.description!,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ]),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
}