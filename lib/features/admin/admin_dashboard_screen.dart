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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = await DatabaseHelper.instance.database;
    final users    = (await db.rawQuery('SELECT COUNT(*) as c FROM users WHERE role="user"')).first['c'] as int;
    final vocab    = (await db.rawQuery('SELECT COUNT(*) as c FROM vocabulary')).first['c'] as int;
    final lessons  = (await db.rawQuery('SELECT COUNT(*) as c FROM lessons')).first['c'] as int;
    final progress = (await db.rawQuery('SELECT COUNT(*) as c FROM user_progress')).first['c'] as int;
    setState(() {
      _stats = {'users': users, 'vocab': vocab, 'lessons': lessons, 'progress': progress};
      _loading = false;
    });
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.red.shade700,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats grid — dùng Row thay GridView để tránh overflow
            Row(children: [
              Expanded(child: _StatCard('Học viên',
                  '${_stats['users'] ?? 0}',
                  Icons.people_rounded, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard('Từ vựng',
                  '${_stats['vocab'] ?? 0}',
                  Icons.book_rounded, Colors.green)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _StatCard('Bài học',
                  '${_stats['lessons'] ?? 0}',
                  Icons.assignment_rounded, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard('Lượt làm',
                  '${_stats['progress'] ?? 0}',
                  Icons.assignment_turned_in_rounded, Colors.purple)),
            ]),
            const SizedBox(height: 24),

            const Text('Quản lý',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            _MenuTile(
              icon: Icons.add_circle_rounded, color: Colors.green,
              title: 'Thêm bài học mới',
              subtitle: 'Reading / Listening / Grammar',
              onTap: () => Navigator.pushNamed(context, '/admin/lesson',
                  arguments: null),
            ),
            _MenuTile(
              icon: Icons.library_books_rounded, color: Colors.blue,
              title: 'Quản lý bài học',
              subtitle: 'Xem, sửa, xóa bài học',
              onTap: () => Navigator.pushNamed(context, '/admin/lessons'),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 26,
              fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.color,
    required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12), shape: BoxShape.circle),
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
