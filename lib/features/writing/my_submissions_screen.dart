// lib/features/writing/my_submissions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/submission_provider.dart';
import '../../core/models/models.dart';

class MySubmissionsScreen extends StatefulWidget {
  const MySubmissionsScreen({super.key});
  @override
  State<MySubmissionsScreen> createState() => _MySubmissionsScreenState();
}

class _MySubmissionsScreenState extends State<MySubmissionsScreen> {
  static const _color = Color(0xFF6A1B9A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        context.read<SubmissionProvider>().loadMySubmissions(
            auth.currentUser!.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sp   = context.watch<SubmissionProvider>();
    final list = sp.mySubmissions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài viết của tôi'),
        backgroundColor: _color,
        foregroundColor: Colors.white,
      ),
      body: sp.loading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
          ? _empty()
          : RefreshIndicator(
        onRefresh: () async {
          final auth = context.read<AuthProvider>();
          if (auth.isLoggedIn) {
            await context
                .read<SubmissionProvider>()
                .loadMySubmissions(auth.currentUser!.id!);
          }
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) => _SubmissionCard(sub: list[i]),
        ),
      ),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.assignment_outlined,
          size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text('Chưa có bài nộp nào',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
      const SizedBox(height: 6),
      Text('Hãy làm bài writing để thấy kết quả tại đây',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
    ]),
  );
}

class _SubmissionCard extends StatelessWidget {
  final SubmissionModel sub;
  const _SubmissionCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final isPending = sub.status == 'pending';
    final pct = (!isPending && sub.maxScore != null && sub.maxScore! > 0)
        ? (sub.score ?? 0) / sub.maxScore!
        : null;

    Color scoreColor = Colors.green;
    if (pct != null) {
      if (pct < 0.5)       scoreColor = Colors.red;
      else if (pct < 0.75) scoreColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header: tiêu đề bài + badge trạng thái
            Row(children: [
              Expanded(
                child: Text(
                  sub.lessonTitle ?? 'Bài viết',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(isPending: isPending),
            ]),
            const SizedBox(height: 6),

            // Câu hỏi
            Text(
              sub.questionText ?? '',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade600, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // Điểm hoặc "đang chấm"
            if (isPending)
              Row(children: [
                Icon(Icons.hourglass_top_rounded,
                    size: 16, color: Colors.orange.shade600),
                const SizedBox(width: 6),
                Text('Đang chờ admin chấm...',
                    style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ])
            else ...[
              // Progress bar điểm
              Row(children: [
                Text(
                  '${sub.score ?? 0} / ${sub.maxScore ?? 100}',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: scoreColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct ?? 0,
                      backgroundColor: Colors.grey.shade200,
                      color: scoreColor,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  pct != null ? '${(pct * 100).round()}%' : '',
                  style: TextStyle(
                      fontSize: 12,
                      color: scoreColor,
                      fontWeight: FontWeight.w600),
                ),
              ]),
              if (sub.feedback != null && sub.feedback!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.comment_outlined,
                            size: 14, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sub.feedback!,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade800,
                                height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                ),
              ],
            ],

            const SizedBox(height: 8),
            Text(
              'Nộp lúc: ${_fmt(sub.submittedAt)}',
              style:
              TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ]),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final isPending = sub.status == 'pending';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(sub.lessonTitle ?? 'Chi tiết bài viết',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _StatusBadge(isPending: isPending),
            const SizedBox(height: 16),

            _Section(title: 'Câu hỏi', child: Text(sub.questionText ?? '',
                style: const TextStyle(fontSize: 14, height: 1.5))),
            const SizedBox(height: 12),

            _Section(
              title: 'Bài làm của bạn',
              child: Text(sub.answerText,
                  style: const TextStyle(fontSize: 14, height: 1.6)),
            ),
            const SizedBox(height: 12),

            if (!isPending) ...[
              _Section(
                title: 'Điểm số',
                child: Row(children: [
                  Text(
                    '${sub.score ?? 0}',
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold,
                        color: Color(0xFF6A1B9A)),
                  ),
                  Text(' / ${sub.maxScore ?? 100}',
                      style: TextStyle(
                          fontSize: 18, color: Colors.grey.shade500)),
                ]),
              ),
              const SizedBox(height: 12),
              if (sub.feedback != null && sub.feedback!.isNotEmpty)
                _Section(
                  title: 'Nhận xét của giáo viên',
                  child: Text(sub.feedback!,
                      style: const TextStyle(fontSize: 14, height: 1.6)),
                ),
              const SizedBox(height: 12),
              if (sub.gradedAt != null)
                Text('Chấm lúc: ${_fmt(sub.gradedAt!)}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade400)),
            ],

            const SizedBox(height: 8),
            Text('Nộp lúc: ${_fmt(sub.submittedAt)}',
                style:
                TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isPending;
  const _StatusBadge({required this.isPending});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isPending
                ? Colors.orange.shade300
                : Colors.green.shade300),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          isPending
              ? Icons.hourglass_top_rounded
              : Icons.check_circle_rounded,
          size: 12,
          color: isPending
              ? Colors.orange.shade700
              : Colors.green.shade700,
        ),
        const SizedBox(width: 4),
        Text(
          isPending ? 'Đang chấm' : 'Đã chấm',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isPending
                  ? Colors.orange.shade700
                  : Colors.green.shade700),
        ),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.5)),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: child,
      ),
    ]);
  }
}