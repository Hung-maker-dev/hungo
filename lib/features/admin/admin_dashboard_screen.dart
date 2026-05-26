// lib/features/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = await DatabaseHelper.instance.database;
    final users = (await db.rawQuery('SELECT COUNT(*) as c FROM users WHERE role="user"')).first['c'] as int;
    final vocab = (await db.rawQuery('SELECT COUNT(*) as c FROM vocabulary')).first['c'] as int;
    final lessons = (await db.rawQuery('SELECT COUNT(*) as c FROM lessons')).first['c'] as int;
    final submissions = (await db.rawQuery('SELECT COUNT(*) as c FROM user_progress')).first['c'] as int;
    setState(() => _stats = {'users': users, 'vocab': vocab, 'lessons': lessons, 'submissions': submissions});
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(child: Text('Không có quyền truy cập')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.red.shade700,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats grid
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatCard('Học viên', '${_stats['users'] ?? 0}', Icons.people_rounded, Colors.blue),
                _StatCard('Từ vựng', '${_stats['vocab'] ?? 0}', Icons.book_rounded, Colors.green),
                _StatCard('Bài học', '${_stats['lessons'] ?? 0}', Icons.assignment_rounded, Colors.orange),
                _StatCard('Lượt làm', '${_stats['submissions'] ?? 0}', Icons.assignment_turned_in_rounded, Colors.purple),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Quản lý', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            _MenuTile(
              icon: Icons.add_circle_rounded, color: Colors.green,
              title: 'Thêm bài học', subtitle: 'Reading / Listening',
              onTap: () => Navigator.pushNamed(context, '/admin/lesson', arguments: null),
            ),
            _MenuTile(
              icon: Icons.library_books_rounded, color: Colors.blue,
              title: 'Quản lý bài học',
              subtitle: 'Xem, sửa, xóa bài học',
              onTap: () => Navigator.pushNamed(context, '/admin/lesson', arguments: 'list'),
            ),
            _MenuTile(
              icon: Icons.spellcheck_rounded, color: Colors.teal,
              title: 'Thêm từ vựng',
              subtitle: 'Thêm vào từ điển nội bộ',
              onTap: () => Navigator.pushNamed(context, '/admin/vocab'),
            ),
            _MenuTile(
              icon: Icons.people_rounded, color: Colors.orange,
              title: 'Danh sách người dùng',
              subtitle: 'Quản lý tài khoản',
              onTap: () => Navigator.pushNamed(context, '/admin/users'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.color, required this.title,
      required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: onTap,
      ),
    );
  }
}
