// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/progress_provider.dart';
import '../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) context.read<ProgressProvider>().loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prog = context.watch<ProgressProvider>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hồ sơ')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.person_outline_rounded, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Đăng nhập để xem hồ sơ',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Đăng nhập'),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('Tạo tài khoản'),
              ),
            ]),
          ),
        ),
      );
    }

    final user = auth.currentUser!;
    final scores = prog.scores;
    final skills = ['vocabulary', 'grammar', 'reading', 'listening'];
    final skillNames = {'vocabulary': 'Từ vựng', 'grammar': 'Ngữ pháp',
        'reading': 'Đọc', 'listening': 'Nghe'};
    final skillColors = [AppTheme.skillVocab, AppTheme.skillGrammar,
        AppTheme.skillReading, AppTheme.skillListening];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
          if (user.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => Navigator.pushNamed(context, '/admin'),
              tooltip: 'Admin Panel',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => prog.loadAll(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Avatar + Info ──────────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primary.withOpacity(0.15),
                    child: Text(
                      user.username.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold,
                          color: AppTheme.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user.username,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(user.email,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.isAdmin
                              ? Colors.red.withOpacity(0.1)
                              : AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(user.isAdmin ? '👑 Admin' : '🎓 Học viên',
                            style: TextStyle(
                              color: user.isAdmin ? Colors.red : AppTheme.primary,
                              fontWeight: FontWeight.w600, fontSize: 12,
                            )),
                      ),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // ── Tổng điểm ─────────────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Tổng điểm',
                      value: '${prog.totalPoints()}',
                      icon: Icons.star_rounded,
                    ),
                    _StatItem(
                      label: 'Chuỗi ngày',
                      value: '${(prog.streaks.values.fold(0, (a, b) => a > b ? a : b))} 🔥',
                      icon: Icons.local_fire_department_rounded,
                    ),
                    _StatItem(
                      label: 'Bài đã làm',
                      value: '${prog.recentProgress.length}',
                      icon: Icons.assignment_turned_in_rounded,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Biểu đồ điểm mỗi kỹ năng (fl_chart) ──────────────────────
            if (scores.isNotEmpty) ...[
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Điểm theo kỹ năng',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: BarChart(BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (scores.values.fold(0, (a, b) => a > b ? a : b) * 1.2)
                            .clamp(100, double.infinity).toDouble(),
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final labels = ['Từ', 'Ngữ', 'Đọc', 'Nghe'];
                                final i = v.toInt();
                                return i < labels.length
                                    ? Text(labels[i], style: const TextStyle(fontSize: 11))
                                    : const SizedBox();
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(skills.length, (i) => BarChartGroupData(
                          x: i,
                          barRods: [BarChartRodData(
                            toY: (scores[skills[i]] ?? 0).toDouble(),
                            color: skillColors[i],
                            width: 28,
                            borderRadius: BorderRadius.circular(6),
                          )],
                        )),
                      )),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Điểm từng kỹ năng ─────────────────────────────────────────
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chi tiết kỹ năng',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    ...List.generate(skills.length, (i) {
                      final pts = scores[skills[i]] ?? 0;
                      final streak = prog.streaks[skills[i]] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: skillColors[i].withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(_skillIcon(skills[i]),
                                color: skillColors[i], size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(skillNames[skills[i]]!,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text('$pts đ', style: TextStyle(
                                      color: skillColors[i], fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pts > 0 ? (pts / (pts + 100)).clamp(0.0, 1.0) : 0,
                                  backgroundColor: Colors.grey.shade200,
                                  color: skillColors[i],
                                  minHeight: 6,
                                ),
                              ),
                              if (streak > 0)
                                Text('🔥 $streak ngày liên tiếp',
                                    style: const TextStyle(fontSize: 11, color: Colors.orange)),
                            ],
                          )),
                        ]),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Đăng xuất ─────────────────────────────────────────────────
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded, color: Colors.red),
              label: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  IconData _skillIcon(String skill) {
    switch (skill) {
      case 'vocabulary': return Icons.search_rounded;
      case 'grammar': return Icons.edit_note_rounded;
      case 'reading': return Icons.chrome_reader_mode_rounded;
      case 'listening': return Icons.headphones_rounded;
      default: return Icons.star_rounded;
    }
  }

  void _logout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ctx.read<AuthProvider>().logout();
              if (ctx.mounted) Navigator.pushReplacementNamed(ctx, '/home');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: Colors.white, size: 28),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: Colors.white,
          fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]);
  }
}
