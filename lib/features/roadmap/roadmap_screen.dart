// lib/features/roadmap/roadmap_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/roadmap_provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});
  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        context.read<RoadmapProvider>().loadActiveRoadmap(auth.currentUser!.id!);
      }
    });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rp = context.watch<RoadmapProvider>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lộ trình học')),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.route_rounded, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Đăng nhập để tạo lộ trình học',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('Đăng nhập'),
          ),
        ])),
      );
    }

    if (rp.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!rp.hasRoadmap) {
      return _NoRoadmapView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lộ trình học'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Tạo lộ trình mới',
            onPressed: () => Navigator.pushNamed(context, '/roadmap/setup'),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Hôm nay'),
            Tab(text: 'Tiến độ'),
            Tab(text: 'Thống kê'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _TodayTab(rp: rp),
          _ProgressTab(rp: rp),
          _StatsTab(rp: rp),
        ],
      ),
    );
  }
}

// ── Tab 1: Nhiệm vụ hôm nay ──────────────────────────────────────────────────
class _TodayTab extends StatelessWidget {
  final RoadmapProvider rp;
  const _TodayTab({required this.rp});

  static const _skillColors = {
    'vocabulary': AppTheme.skillVocab,
    'grammar':    AppTheme.skillGrammar,
    'reading':    AppTheme.skillReading,
    'listening':  AppTheme.skillListening,
  };
  static const _skillIcons = {
    'vocabulary': '📖',
    'grammar':    '✏️',
    'reading':    '📰',
    'listening':  '🎧',
  };

  @override
  Widget build(BuildContext context) {
    final roadmap = rp.activeRoadmap!;
    final tasks = rp.todayTasks;
    final now = DateTime.now();

    return RefreshIndicator(
      onRefresh: () async {
        final auth = context.read<AuthProvider>();
        await rp.loadActiveRoadmap(auth.currentUser!.id!);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header card ────────────────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(
                    _goalLabel(roadmap.goal),
                    style: const TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold),
                  )),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white24, borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Tuần ${(roadmap.daysPassed ~/ 7) + 1}/${roadmap.durationWeeks}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ]),
                const SizedBox(height: 12),
                // Progress tổng
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: roadmap.overallProgress,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${(roadmap.overallProgress * 100).round()}% hoàn thành',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  Text('Còn ${roadmap.daysLeft} ngày',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // ── Tiến độ hôm nay ────────────────────────────────────────────
          Row(children: [
            Expanded(child: _MiniStat(
              '${rp.todayDone}/${rp.todayTotal}',
              'Nhiệm vụ xong',
              Icons.task_alt_rounded,
              Colors.green,
            )),
            const SizedBox(width: 12),
            Expanded(child: _MiniStat(
              '${(rp.todayProgress * 100).round()}%',
              'Hôm nay',
              Icons.pie_chart_rounded,
              AppTheme.primary,
            )),
            const SizedBox(width: 12),
            Expanded(child: _MiniStat(
              '${rp.currentStreak}🔥',
              'Chuỗi ngày',
              Icons.local_fire_department_rounded,
              Colors.orange,
            )),
          ]),
          const SizedBox(height: 20),

          // ── Danh sách nhiệm vụ ─────────────────────────────────────────
          Text('Nhiệm vụ hôm nay — ${now.day}/${now.month}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          if (tasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(children: [
                  const Icon(Icons.celebration_rounded, size: 60, color: Colors.amber),
                  const SizedBox(height: 12),
                  const Text('Tuyệt vời! Hôm nay không có nhiệm vụ.',
                      textAlign: TextAlign.center),
                ]),
              ),
            )
          else
            ...tasks.map((task) => _TaskCard(
              task: task,
              color: _skillColors[task.skill] ?? AppTheme.primary,
              icon: _skillIcons[task.skill] ?? '📌',
              onComplete: () async {
                await rp.completeTask(task, doneCount: task.targetCount - task.doneCount);
                if (context.mounted && rp.todayDone == rp.todayTotal) {
                  _showDayComplete(context);
                }
              },
            )),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showDayComplete(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: const Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🎉', style: TextStyle(fontSize: 60)),
          SizedBox(height: 12),
          Text('Hoàn thành hôm nay!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Bạn đã hoàn thành tất cả nhiệm vụ hôm nay. Tiếp tục chuỗi ngày học nhé!',
              textAlign: TextAlign.center),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tuyệt vời! 💪'),
          ),
        ],
      ),
    );
  }

  String _goalLabel(String goal) {
    switch (goal) {
      case 'ielts': return '🎓 Lộ trình IELTS';
      case 'toeic': return '💼 Lộ trình TOEIC';
      case 'communication': return '💬 Lộ trình Giao tiếp';
      case 'business': return '📊 Lộ trình Kinh doanh';
      case 'vstep': return '🏫 Lộ trình VSTEP';
      default: return '🎯 Lộ trình học';
    }
  }
}

// ── Widget từ vựng ngẫu nhiên ───────────────────────────────────────────────
class _RandomVocabWidget extends StatefulWidget {
  @override
  State<_RandomVocabWidget> createState() => _RandomVocabWidgetState();
}

class _RandomVocabWidgetState extends State<_RandomVocabWidget> {
  Map<String, dynamic>? _word;
  bool _loading = false;
  bool _flipped = false;

  static const _topics = ['travel','food','business','technology',
    'health','education','sports','nature','daily life'];

  @override
  void initState() {
    super.initState();
    _loadRandom();
  }

  Future<void> _loadRandom() async {
    setState(() { _loading = true; _flipped = false; });
    try {
      final db = await DatabaseHelper.instance.database;
      final topic = (_topics..shuffle()).first;
      // Lấy ngẫu nhiên 1 từ từ topic hoặc bất kỳ
      List<Map<String, dynamic>> rows = await db.rawQuery(
          'SELECT * FROM vocabulary WHERE topic = ? ORDER BY RANDOM() LIMIT 1',
          [topic]);
      if (rows.isEmpty) {
        rows = await db.rawQuery(
            'SELECT * FROM vocabulary ORDER BY RANDOM() LIMIT 1');
      }
      if (mounted) setState(() { _word = rows.isNotEmpty ? rows.first : null; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Row(children: [
              Icon(Icons.auto_stories_rounded, color: AppTheme.skillVocab, size: 20),
              SizedBox(width: 8),
              Text('Từ vựng hôm nay',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary, size: 20),
              onPressed: _loadRandom,
              tooltip: 'Từ mới',
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            ),
          ]),
          const SizedBox(height: 12),
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _word == null
              ? Center(child: Column(children: [
            Text('Chưa có từ vựng. Hãy search để thêm!',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/vocab/search'),
              child: const Text('Search từ ngay'),
            ),
          ]))
              : GestureDetector(
            onTap: () => setState(() => _flipped = !_flipped),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _flipped
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: _buildFront(),
              secondChild: _buildBack(),
            ),
          ),
          if (_word != null && !_loading) ...[
            const SizedBox(height: 10),
            Text(_flipped ? 'Nhấn để xem từ' : 'Nhấn để xem nghĩa',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ]),
      ),
    );
  }

  Widget _buildFront() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppTheme.primary, AppTheme.primaryDark],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(children: [
      Text(_word!['word'] ?? '',
          style: const TextStyle(color: Colors.white, fontSize: 28,
              fontWeight: FontWeight.bold)),
      if (_word!['phonetic'] != null)
        Text(_word!['phonetic'], style: const TextStyle(
            color: Colors.white70, fontSize: 14)),
      if (_word!['part_of_speech'] != null)
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: Colors.white24,
              borderRadius: BorderRadius.circular(8)),
          child: Text(_word!['part_of_speech'],
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      if (_word!['topic'] != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            "📌 ${_word!['topic']}",
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ),
    ]),
  );

  Widget _buildBack() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.primary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(_word!['definition'] ?? '',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.5)),
      if (_word!['definition_vi'] != null) ...[
        const SizedBox(height: 6),
        Text(
          "🇻🇳 ${_word!['definition_vi']}",
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
      ],
      if (_word!['example'] != null) ...[
        const SizedBox(height: 8),
        Text(
          "\"${_word!['example']}\"",
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ],
    ]),
  );
}

// ── Tab 2: Tiến độ tổng thể ──────────────────────────────────────────────────
class _ProgressTab extends StatelessWidget {
  final RoadmapProvider rp;
  const _ProgressTab({required this.rp});

  @override
  Widget build(BuildContext context) {
    final roadmap = rp.activeRoadmap!;
    final stats = rp.stats;
    final last7 = stats.length > 7 ? stats.sublist(stats.length - 7) : stats;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Biểu đồ hoàn thành 7 ngày gần nhất
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Hoàn thành 7 ngày gần nhất',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 16),
              SizedBox(
                height: 160,
                child: last7.isEmpty
                    ? const Center(child: Text('Chưa có dữ liệu'))
                    : BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i >= last7.length) return const SizedBox();
                        final d = DateTime.parse(last7[i].date);
                        return Text('${d.day}/${d.month}',
                            style: const TextStyle(fontSize: 10));
                      },
                    )),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(last7.length, (i) {
                    final pct = (last7[i].completionRate * 100);
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: pct,
                        color: pct >= 80 ? Colors.green
                            : pct >= 50 ? AppTheme.primary : Colors.red.shade300,
                        width: 28,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ]);
                  }),
                )),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Tiến độ tổng
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tiến độ lộ trình',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 16),
              _ProgressRow('Ngày đã qua', '${roadmap.daysPassed}/${roadmap.totalDays}',
                  roadmap.overallProgress, AppTheme.primary),
              const SizedBox(height: 12),
              _ProgressRow('Ngày học đủ', '${rp.totalDaysStudied}/${roadmap.daysPassed}',
                  roadmap.daysPassed > 0 ? rp.totalDaysStudied / roadmap.daysPassed : 0,
                  Colors.green),
              const SizedBox(height: 12),
              _ProgressRow('Tỉ lệ hoàn thành TB',
                  '${(rp.avgCompletionRate * 100).round()}%',
                  rp.avgCompletionRate, Colors.orange),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Lịch sử từng ngày
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Lịch sử học tập',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              if (stats.isEmpty)
                const Center(child: Text('Chưa có dữ liệu'))
              else
                ...stats.reversed.take(14).map((s) {
                  final d = DateTime.parse(s.date);
                  final rate = s.completionRate;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(children: [
                      SizedBox(width: 56, child: Text('${d.day}/${d.month}',
                          style: const TextStyle(fontWeight: FontWeight.w500))),
                      Expanded(child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: rate, minHeight: 10,
                          backgroundColor: Colors.grey.shade200,
                          color: rate >= 0.8 ? Colors.green
                              : rate >= 0.5 ? AppTheme.primary : Colors.red.shade300,
                        ),
                      )),
                      const SizedBox(width: 8),
                      Text('${(rate * 100).round()}%',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: rate >= 0.8 ? Colors.green : AppTheme.primary,
                              fontSize: 12)),
                    ]),
                  );
                }),
            ]),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Tab 3: Thống kê tổng kết ─────────────────────────────────────────────────
class _StatsTab extends StatelessWidget {
  final RoadmapProvider rp;
  const _StatsTab({required this.rp});

  @override
  Widget build(BuildContext context) {
    final roadmap = rp.activeRoadmap!;
    final rate = rp.avgCompletionRate;
    String evaluation;
    String evalIcon;
    Color evalColor;

    if (rate >= 0.9) {
      evaluation = 'Xuất sắc! Bạn đang học rất đều đặn và hiệu quả.';
      evalIcon = '🏆'; evalColor = Colors.amber;
    } else if (rate >= 0.7) {
      evaluation = 'Tốt! Bạn đang trên đà đúng. Duy trì thêm nhé!';
      evalIcon = '👍'; evalColor = Colors.green;
    } else if (rate >= 0.5) {
      evaluation = 'Khá ổn. Cố gắng hoàn thành nhiều hơn mỗi ngày nhé!';
      evalIcon = '💪'; evalColor = Colors.orange;
    } else {
      evaluation = 'Cần cố gắng hơn. Chỉ 15 phút mỗi ngày thôi, bạn làm được!';
      evalIcon = '📣'; evalColor = Colors.red;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Đánh giá tổng
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: evalColor.withOpacity(0.08),
              border: Border.all(color: evalColor.withOpacity(0.4)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Text(evalIcon, style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 8),
              Text('Đánh giá tổng thể',
                  style: TextStyle(color: evalColor, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(evaluation, textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.5)),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Số liệu tổng
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _StatCard('📅 Ngày đã học', '${rp.totalDaysStudied}', 'ngày', Colors.blue),
            _StatCard('📖 Từ đã học', '${rp.totalWordsLearned}', 'từ', Colors.green),
            _StatCard('⏱ Tổng thời gian', '${rp.totalMinutes}', 'phút', Colors.orange),
            _StatCard('🔥 Chuỗi hiện tại', '${rp.currentStreak}', 'ngày liên tiếp', Colors.red),
          ],
        ),
        const SizedBox(height: 16),

        // Tỉ lệ hoàn thành vòng tròn
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const Text('Tỉ lệ hoàn thành trung bình',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: PieChart(PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: rate * 100,
                      color: evalColor,
                      title: '${(rate * 100).round()}%',
                      titleStyle: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.bold, fontSize: 18),
                      radius: 60,
                    ),
                    PieChartSectionData(
                      value: (1 - rate) * 100,
                      color: Colors.grey.shade200,
                      title: '',
                      radius: 50,
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                )),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Thông tin lộ trình
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Thông tin lộ trình',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 12),
              _InfoRow('Mục tiêu', _goalLabel(roadmap.goal)),
              if (roadmap.targetScore != null)
                _InfoRow('Điểm mục tiêu', roadmap.targetScore!),
              _InfoRow('Trình độ bắt đầu', roadmap.levelStart),
              _InfoRow('Thời lượng', '${roadmap.durationWeeks} tuần'),
              _InfoRow('Ngày bắt đầu', _fmtDate(roadmap.startDate)),
              _InfoRow('Ngày kết thúc', _fmtDate(roadmap.endDate)),
              _InfoRow('Học/ngày', '${roadmap.dailyMinutes} phút'),
            ]),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  String _goalLabel(String goal) {
    const m = {'ielts':'IELTS','toeic':'TOEIC','communication':'Giao tiếp','business':'Kinh doanh','vstep':'VSTEP'};
    return m[goal] ?? goal;
  }

  String _fmtDate(String iso) {
    final d = DateTime.parse(iso);
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ── Màn hình chưa có lộ trình ─────────────────────────────────────────────────
class _NoRoadmapView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lộ trình học')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.route_rounded,
                  size: 56, color: AppTheme.primary),
            ),
            const SizedBox(height: 24),
            const Text('Bạn chưa có lộ trình học',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Tạo lộ trình cá nhân hóa phù hợp với mục tiêu của bạn',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/roadmap/setup'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tạo lộ trình ngay'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Widgets phụ ──────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final DailyTask task;
  final Color color;
  final String icon;
  final VoidCallback onComplete;
  const _TaskCard({required this.task, required this.color,
    required this.icon, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: task.isCompleted ? Colors.green.withOpacity(0.12)
                  : color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(
              task.isCompleted ? '✅' : icon,
              style: const TextStyle(fontSize: 22),
            )),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.taskLabel,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    color: task.isCompleted ? Colors.grey : null)),
            const SizedBox(height: 4),
            if (task.targetCount > 1) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: task.progress,
                  backgroundColor: Colors.grey.shade200,
                  color: task.isCompleted ? Colors.green : color,
                  minHeight: 5,
                ),
              ),
              const SizedBox(height: 2),
              Text('${task.doneCount}/${task.targetCount}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ])),
          if (!task.isCompleted)
            TextButton(
              onPressed: onComplete,
              child: Text('Xong', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            )
          else
            Icon(Icons.check_circle_rounded, color: Colors.green.shade400),
        ]),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _MiniStat(this.value, this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final String label, value;
  final double progress;
  final Color color;
  const _ProgressRow(this.label, this.value, this.progress, this.color);
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0), minHeight: 8,
          backgroundColor: Colors.grey.shade200, color: color,
        ),
      ),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String title, value, unit;
  final Color color;
  const _StatCard(this.title, this.value, this.unit, this.color);
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(title, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          Text(unit, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ]),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label,
            style: TextStyle(color: Colors.grey.shade600))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
