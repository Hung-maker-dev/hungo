// lib/features/admin/admin_grading_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/submission_provider.dart';
import '../../core/models/models.dart';

class AdminGradingScreen extends StatefulWidget {
  const AdminGradingScreen({super.key});
  @override
  State<AdminGradingScreen> createState() => _AdminGradingScreenState();
}

class _AdminGradingScreenState extends State<AdminGradingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubmissionProvider>().loadPending();
      context.read<SubmissionProvider>().loadAll(status: 'graded');
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp      = context.watch<SubmissionProvider>();
    final pending = sp.pendingList;
    final graded  = sp.allSubmissions
        .where((s) => s.status == 'graded')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Text('Chấm bài Writing'),
          if (pending.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('${pending.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Chờ chấm (${pending.length})'),
            Tab(text: 'Đã chấm (${graded.length})'),
          ],
        ),
      ),
      body: sp.loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tab,
        children: [
          _PendingList(list: pending),
          _GradedList(list: graded),
        ],
      ),
    );
  }
}

// ── Tab 1: Chờ chấm ──────────────────────────────────────────────────────────
class _PendingList extends StatelessWidget {
  final List<SubmissionModel> list;
  const _PendingList({required this.list});

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 64, color: Colors.green.shade300),
          const SizedBox(height: 12),
          const Text('Không có bài chờ chấm 🎉',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Tất cả bài đã được chấm xong',
              style: TextStyle(color: Colors.grey.shade500)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<SubmissionProvider>().loadPending(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _PendingCard(sub: list[i]),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final SubmissionModel sub;
  const _PendingCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openGradeDialog(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.red.shade100,
                child: Text(
                  (sub.username ?? '?')[0].toUpperCase(),
                  style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sub.username ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(sub.lessonTitle ?? '',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Text('Chờ chấm',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 10),

            // Câu hỏi
            Text('📝 ${sub.questionText ?? ''}',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),

            // Preview bài làm
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                sub.answerText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style:
                const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 8),

            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nộp: ${_fmt(sub.submittedAt)}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400)),
                  TextButton.icon(
                    icon: const Icon(Icons.grading_rounded, size: 16),
                    label: const Text('Chấm ngay'),
                    onPressed: () => _openGradeDialog(context),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade700),
                  ),
                ]),
          ]),
        ),
      ),
    );
  }

  void _openGradeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _GradeSheet(sub: sub),
    );
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// ── Sheet chấm điểm ──────────────────────────────────────────────────────────
class _GradeSheet extends StatefulWidget {
  final SubmissionModel sub;
  const _GradeSheet({required this.sub});
  @override
  State<_GradeSheet> createState() => _GradeSheetState();
}

class _GradeSheetState extends State<_GradeSheet> {
  late int _score;
  final _feedbackCtrl = TextEditingController();
  bool _saving = false;

  int get _maxScore => widget.sub.maxScore ?? 100;

  @override
  void initState() {
    super.initState();
    _score = (_maxScore * 0.7).round(); // mặc định 70%
  }

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<SubmissionProvider>().gradeSubmission(
      submissionId: widget.sub.id!,
      score:        _score,
      maxScore:     _maxScore,
      feedback:     _feedbackCtrl.text.trim().isEmpty
          ? null
          : _feedbackCtrl.text.trim(),
      userId:    widget.sub.userId,
      lessonId:  widget.sub.lessonId,
      skill:     'writing',
      timeSpent: 0,
    );

    // reload graded tab
    await context.read<SubmissionProvider>().loadAll(status: 'graded');

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Đã chấm $_score/$_maxScore điểm cho ${widget.sub.username}'),
          ]),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = _score / _maxScore;
    Color scoreColor = Colors.green;
    if (pct < 0.5)       scoreColor = Colors.red;
    else if (pct < 0.75) scoreColor = Colors.orange;

    return Padding(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              // Tiêu đề
              Row(children: [
                CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: Text(
                    (widget.sub.username ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.sub.username ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(widget.sub.lessonTitle ?? '',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                      ]),
                ),
              ]),
              const SizedBox(height: 16),

              // Câu hỏi
              _Label('Câu hỏi'),
              const SizedBox(height: 4),
              _Box(child: Text(widget.sub.questionText ?? '',
                  style: const TextStyle(fontSize: 14, height: 1.5))),
              const SizedBox(height: 12),

              // Bài làm
              _Label('Bài làm của học viên'),
              const SizedBox(height: 4),
              _Box(
                child: Text(widget.sub.answerText,
                    style: const TextStyle(fontSize: 14, height: 1.6)),
              ),
              const SizedBox(height: 12),

              // Đáp án mẫu (nếu có)
              if (widget.sub.questionText != null) ...[
                _Label('Đáp án mẫu (tham khảo)'),
                const SizedBox(height: 4),
                _Box(
                  color: Colors.green.shade50,
                  child: Text(
                    // sample_answer được join từ DB query
                    'Xem trong hệ thống câu hỏi',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                        fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Slider điểm
              _Label('Điểm số  (tối đa $_maxScore)'),
              const SizedBox(height: 8),
              Row(children: [
                Text(
                  '$_score',
                  style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: scoreColor),
                ),
                Text(' / $_maxScore',
                    style: TextStyle(
                        fontSize: 18, color: Colors.grey.shade400)),
                const Spacer(),
                Text('${(pct * 100).round()}%',
                    style: TextStyle(
                        fontSize: 14,
                        color: scoreColor,
                        fontWeight: FontWeight.w600)),
              ]),
              Slider(
                value: _score.toDouble(),
                min: 0,
                max: _maxScore.toDouble(),
                divisions: _maxScore,
                activeColor: scoreColor,
                label: '$_score',
                onChanged: (v) => setState(() => _score = v.round()),
              ),

              // Nhanh chọn %
              Row(children: [
                for (final pctVal in [0.5, 0.6, 0.7, 0.8, 0.9, 1.0])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: OutlinedButton(
                        onPressed: () =>
                            setState(() => _score = (_maxScore * pctVal).round()),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          side: BorderSide(
                              color: _score == (_maxScore * pctVal).round()
                                  ? scoreColor
                                  : Colors.grey.shade300),
                          backgroundColor:
                          _score == (_maxScore * pctVal).round()
                              ? scoreColor.withOpacity(0.1)
                              : null,
                        ),
                        child: Text(
                          '${(pctVal * 100).round()}%',
                          style: TextStyle(
                              fontSize: 11,
                              color: _score == (_maxScore * pctVal).round()
                                  ? scoreColor
                                  : Colors.grey.shade600),
                        ),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),

              // Nhận xét
              _Label('Nhận xét (tùy chọn)'),
              const SizedBox(height: 6),
              TextField(
                controller: _feedbackCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                  'Nhập nhận xét, góp ý cho học viên...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.comment_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // Nút lưu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _saving
                      ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Đang lưu...' : 'Xác nhận điểm'),
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ]),
      ),
    );
  }
}

// ── Tab 2: Đã chấm ───────────────────────────────────────────────────────────
class _GradedList extends StatelessWidget {
  final List<SubmissionModel> list;
  const _GradedList({required this.list});

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return Center(
        child: Text('Chưa có bài nào được chấm',
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          context.read<SubmissionProvider>().loadAll(status: 'graded'),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _GradedCard(sub: list[i]),
      ),
    );
  }
}

class _GradedCard extends StatelessWidget {
  final SubmissionModel sub;
  const _GradedCard({required this.sub});

  @override
  Widget build(BuildContext context) {
    final pct = (sub.maxScore != null && sub.maxScore! > 0)
        ? (sub.score ?? 0) / sub.maxScore!
        : 0.0;
    Color scoreColor = Colors.green;
    if (pct < 0.5)       scoreColor = Colors.red;
    else if (pct < 0.75) scoreColor = Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: scoreColor.withOpacity(0.15),
            child: Text(
              (sub.username ?? '?')[0].toUpperCase(),
              style: TextStyle(
                  color: scoreColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub.username ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(sub.lessonTitle ?? '',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.toDouble(),
                      backgroundColor: Colors.grey.shade200,
                      color: scoreColor,
                      minHeight: 4,
                    ),
                  ),
                ]),
          ),
          const SizedBox(width: 12),
          Column(children: [
            Text(
              '${sub.score}/${sub.maxScore}',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: scoreColor),
            ),
            Text(
              '${(pct * 100).round()}%',
              style:
              TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.5));
}

class _Box extends StatelessWidget {
  final Widget child;
  final Color? color;
  const _Box({required this.child, this.color});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color ?? Colors.grey.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: child,
  );
}