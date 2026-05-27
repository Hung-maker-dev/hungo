// lib/features/roadmap/roadmap_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/roadmap_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class RoadmapSetupScreen extends StatefulWidget {
  const RoadmapSetupScreen({super.key});
  @override
  State<RoadmapSetupScreen> createState() => _RoadmapSetupScreenState();
}

class _RoadmapSetupScreenState extends State<RoadmapSetupScreen> {
  int _step = 0;

  // Bước 1: Mục tiêu
  String _goal = '';
  String _targetScore = '';

  // Bước 2: Trình độ + thời gian
  String _levelStart = 'A1';
  int _durationWeeks = 8;
  int _dailyMinutes = 30;

  // Bước 3: Kỹ năng focus
  final Set<String> _focusSkills = {'vocabulary','grammar','reading','listening'};

  bool _saving = false;

  static const _goals = [
    {'key': 'ielts',         'icon': '🎓', 'title': 'Thi IELTS',      'desc': 'Luyện thi chứng chỉ quốc tế'},
    {'key': 'toeic',         'icon': '💼', 'title': 'Thi TOEIC',      'desc': 'Tiếng Anh công việc'},
    {'key': 'communication', 'icon': '💬', 'title': 'Giao tiếp',      'desc': 'Nói chuyện tự nhiên, du lịch'},
    {'key': 'business',      'icon': '📊', 'title': 'Kinh doanh',     'desc': 'Email, họp, thuyết trình'},
    {'key': 'vstep',          'icon': '🏫', 'title': 'Thi VSTEP',      'desc': 'Chứng chỉ tiếng Anh Việt Nam (B1→C1)'},
  ];

  static const _levels = ['A1','A2','B1','B2','C1'];
  static const _minutes = [15, 20, 30, 45, 60];
  static const _skillInfo = {
    'vocabulary': {'icon': '📖', 'label': 'Từ vựng'},
    'grammar':    {'icon': '✏️', 'label': 'Ngữ pháp'},
    'reading':    {'icon': '📰', 'label': 'Đọc hiểu'},
    'listening':  {'icon': '🎧', 'label': 'Luyện nghe'},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết lập lộ trình'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 4,
            backgroundColor: Colors.white30,
            color: Colors.white,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: [_step0(), _step1(), _step2(), _step3()][_step],
      ),
    );
  }

  // ── Bước 0: Chọn mục tiêu ────────────────────────────────────────────────
  Widget _step0() => _StepWrapper(
    key: const ValueKey(0),
    title: 'Mục tiêu của bạn là gì?',
    subtitle: 'Chúng mình sẽ tạo lộ trình phù hợp nhất',
    child: Column(
      children: _goals.map((g) => _GoalCard(
        icon: g['icon']!, title: g['title']!, desc: g['desc']!,
        selected: _goal == g['key'],
        onTap: () => setState(() => _goal = g['key']!),
      )).toList(),
    ),
    canNext: _goal.isNotEmpty,
    onNext: () => setState(() => _step = 1),
  );

  // ── Bước 1: Target score + gợi ý tuần ────────────────────────────────────
  Widget _step1() {
    final needScore = _goal == 'ielts' || _goal == 'toeic' || _goal == 'vstep';
    return _StepWrapper(
      key: const ValueKey(1),
      title: needScore ? 'Điểm mục tiêu?' : 'Thời gian học',
      subtitle: needScore ? 'Điền điểm bạn muốn đạt được' : 'Chọn thời lượng phù hợp',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Target score input
        if (needScore) ...[
          if (_goal == 'vstep') ...[
            const Text('Mục tiêu VSTEP:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10,
              children: ['B1', 'B2', 'C1'].map((score) => ChoiceChip(
                label: Text(score, style: const TextStyle(fontWeight: FontWeight.bold)),
                selected: _targetScore == score,
                selectedColor: AppTheme.primary,
                labelStyle: TextStyle(color: _targetScore == score ? Colors.white : null),
                onSelected: (_) => setState(() {
                  _targetScore = score;
                  _durationWeeks = RoadmapProvider.suggestWeeks(_goal, score);
                }),
              )).toList(),
            ),
            const SizedBox(height: 8),
            if (_targetScore.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text(
                    _vstepDesc(_targetScore),
                    style: const TextStyle(fontSize: 13, color: Colors.blue)),
              ),
          ] else ...[
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _goal == 'ielts' ? 'Band IELTS (vd: 6.5)' : 'Điểm TOEIC (vd: 700)',
                prefixIcon: const Icon(Icons.score_rounded),
              ),
              onChanged: (v) {
                setState(() {
                  _targetScore = v;
                  if (v.isNotEmpty) {
                    _durationWeeks = RoadmapProvider.suggestWeeks(_goal, v);
                  }
                });
              },
            ),
          ],
          const SizedBox(height: 20),
        ],

        // Gợi ý tuần
        if (_targetScore.isNotEmpty || !needScore) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.lightbulb_rounded, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Hệ thống gợi ý: $_durationWeeks tuần',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
              )),
            ]),
          ),
          const SizedBox(height: 16),
        ],

        const Text('Số tuần học:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10,
          children: [4, 8, 12, 16].map((w) => ChoiceChip(
            label: Text('$w tuần'),
            selected: _durationWeeks == w,
            selectedColor: AppTheme.primary,
            labelStyle: TextStyle(
                color: _durationWeeks == w ? Colors.white : null,
                fontWeight: FontWeight.w600),
            onSelected: (_) => setState(() => _durationWeeks = w),
          )).toList(),
        ),
        const SizedBox(height: 20),

        const Text('Thời gian học/ngày:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10,
          children: _minutes.map((m) => ChoiceChip(
            label: Text('$m phút'),
            selected: _dailyMinutes == m,
            selectedColor: AppTheme.primary,
            labelStyle: TextStyle(
                color: _dailyMinutes == m ? Colors.white : null,
                fontWeight: FontWeight.w600),
            onSelected: (_) => setState(() => _dailyMinutes = m),
          )).toList(),
        ),
      ]),
      canNext: true,
      onNext: () => setState(() => _step = 2),
      onBack: () => setState(() => _step = 0),
    );
  }

  // ── Bước 2: Trình độ + kỹ năng ───────────────────────────────────────────
  Widget _step2() => _StepWrapper(
    key: const ValueKey(2),
    title: 'Trình độ & Kỹ năng',
    subtitle: 'Trình độ hiện tại và kỹ năng muốn tập trung',
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Trình độ hiện tại:', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10,
        children: _levels.map((l) => ChoiceChip(
          label: Text(l),
          selected: _levelStart == l,
          selectedColor: AppTheme.primary,
          labelStyle: TextStyle(
              color: _levelStart == l ? Colors.white : null,
              fontWeight: FontWeight.bold),
          onSelected: (_) => setState(() => _levelStart = l),
        )).toList(),
      ),
      const SizedBox(height: 24),

      const Text('Kỹ năng muốn luyện:', style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('(Chọn ít nhất 1)', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      const SizedBox(height: 10),
      ...(_skillInfo.entries.map((e) => CheckboxListTile(
        value: _focusSkills.contains(e.key),
        onChanged: (v) => setState(() {
          if (v == true) _focusSkills.add(e.key);
          else if (_focusSkills.length > 1) _focusSkills.remove(e.key);
        }),
        title: Text('${e.value['icon']} ${e.value['label']}',
            style: const TextStyle(fontWeight: FontWeight.w500)),
        activeColor: AppTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: EdgeInsets.zero,
      ))),
    ]),
    canNext: _focusSkills.isNotEmpty,
    onNext: () => setState(() => _step = 3),
    onBack: () => setState(() => _step = 1),
  );

  // ── Bước 3: Xác nhận ─────────────────────────────────────────────────────
  Widget _step3() {
    final goalInfo = _goals.firstWhere((g) => g['key'] == _goal,
        orElse: () => {'key': '', 'icon': '🎯', 'title': 'Lộ trình', 'desc': ''});
    final endDate = DateTime.now().add(Duration(days: _durationWeeks * 7));

    return _StepWrapper(
      key: const ValueKey(3),
      title: 'Xác nhận lộ trình',
      subtitle: 'Kiểm tra lại trước khi bắt đầu',
      child: Column(children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Text('${goalInfo['icon']} ${goalInfo['title']}',
                  style: const TextStyle(color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.bold)),
              if (_targetScore.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Mục tiêu: $_targetScore',
                    style: const TextStyle(color: Colors.white70, fontSize: 15)),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 16),
        _SummaryRow('📅 Thời gian', '$_durationWeeks tuần (${_durationWeeks * 7} ngày)'),
        _SummaryRow('⏱ Mỗi ngày', '$_dailyMinutes phút'),
        _SummaryRow('📊 Trình độ', _levelStart),
        _SummaryRow('🏁 Kết thúc', '${endDate.day}/${endDate.month}/${endDate.year}'),
        _SummaryRow('🎯 Kỹ năng',
            _focusSkills.map((s) => _skillInfo[s]!['label']!).join(', ')),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.green),
            SizedBox(width: 10),
            Expanded(child: Text('Hệ thống sẽ tạo nhiệm vụ mỗi ngày tự động dựa theo lộ trình này.')),
          ]),
        ),
      ]),
      canNext: true,
      nextLabel: _saving ? null : 'Bắt đầu học! 🚀',
      isLoading: _saving,
      onNext: _createRoadmap,
      onBack: () => setState(() => _step = 2),
    );
  }

  String _vstepDesc(String level) {
    switch (level) {
      case 'B1': return 'B1 - Giao tiếp cơ bản, hiểu nội dung quen thuộc trong cuộc sống và công việc.';
      case 'B2': return 'B2 - Giao tiếp tự nhiên, hiểu các văn bản phức tạp về nhiều chủ đề.';
      case 'C1': return 'C1 - Sử dụng thành thạo, linh hoạt tiếng Anh học thuật và chuyên nghiệp.';
      default: return '';
    }
  }

  Future<void> _createRoadmap() async {
    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final rp = context.read<RoadmapProvider>();
    await rp.createRoadmap(
      userId: auth.currentUser!.id!,
      goal: _goal, targetScore: _targetScore.isEmpty ? null : _targetScore,
      levelStart: _levelStart, durationWeeks: _durationWeeks,
      dailyMinutes: _dailyMinutes, focusSkills: _focusSkills.toList(),
    );
    if (mounted) Navigator.pushReplacementNamed(context, '/roadmap');
  }
}

// ── Widgets phụ ──────────────────────────────────────────────────────────────

class _StepWrapper extends StatelessWidget {
  final String title, subtitle;
  final Widget child;
  final bool canNext;
  final String? nextLabel;
  final bool isLoading;
  final VoidCallback? onNext, onBack;

  const _StepWrapper({
    super.key, required this.title, required this.subtitle,
    required this.child, required this.canNext,
    this.nextLabel, this.isLoading = false,
    this.onNext, this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 28),
            child,
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Row(children: [
          if (onBack != null) ...[
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Quay lại'),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: canNext && !isLoading ? onNext : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(nextLabel ?? 'Tiếp theo →',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    ]);
  }
}

class _GoalCard extends StatelessWidget {
  final String icon, title, desc;
  final bool selected;
  final VoidCallback onTap;
  const _GoalCard({required this.icon, required this.title, required this.desc,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.08) : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                color: selected ? AppTheme.primary : null)),
            Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ])),
          if (selected) const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
        ]),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  const _SummaryRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600,
            color: AppTheme.primary))),
      ]),
    );
  }
}
