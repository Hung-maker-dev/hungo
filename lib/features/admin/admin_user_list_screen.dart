// lib/features/admin/admin_user_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});
  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  List<UserModel> _users = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('users', orderBy: 'created_at DESC');
    setState(() {
      _users = rows.map((r) => UserModel.fromMap(r)).toList();
      _loading = false;
    });
  }

  List<UserModel> get _filtered => _search.isEmpty
      ? _users
      : _users.where((u) =>
          u.username.toLowerCase().contains(_search.toLowerCase()) ||
          u.email.toLowerCase().contains(_search.toLowerCase())).toList();

  Future<void> _toggleRole(UserModel user) async {
    final auth = context.read<AuthProvider>();
    if (user.id == auth.currentUser?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể thay đổi role của chính mình')));
      return;
    }
    final newRole = user.role == 'admin' ? 'user' : 'admin';
    final db = await DatabaseHelper.instance.database;
    await db.update('users', {'role': newRole},
        where: 'id = ?', whereArgs: [user.id]);
    await _loadUsers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Đã thay đổi role của ${user.username} thành $newRole'),
        backgroundColor: Colors.green,
      ));
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final auth = context.read<AuthProvider>();
    if (user.id == auth.currentUser?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể xóa tài khoản đang đăng nhập')));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa người dùng?'),
        content: Text('Xóa tài khoản "${user.username}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final db = await DatabaseHelper.instance.database;
    await db.delete('users', where: 'id = ?', whereArgs: [user.id]);
    await _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Người dùng (${_users.length})'),
        backgroundColor: Colors.red.shade700,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên hoặc email...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _search = ''))
                    : null,
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('Không tìm thấy người dùng'))
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final u = _filtered[i];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: u.isAdmin
                                      ? Colors.red.withOpacity(0.15)
                                      : AppTheme.primary.withOpacity(0.12),
                                  child: Text(
                                    u.username.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: u.isAdmin ? Colors.red : AppTheme.primary,
                                    ),
                                  ),
                                ),
                                title: Row(children: [
                                  Text(u.username,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: u.isAdmin
                                          ? Colors.red.withOpacity(0.1)
                                          : AppTheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(u.isAdmin ? '👑 Admin' : '🎓 User',
                                        style: TextStyle(
                                          fontSize: 10, fontWeight: FontWeight.bold,
                                          color: u.isAdmin ? Colors.red : AppTheme.primary,
                                        )),
                                  ),
                                ]),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(u.email,
                                        style: const TextStyle(fontSize: 12)),
                                    if (u.lastLogin != null)
                                      Text(
                                        'Đăng nhập: ${_formatDate(u.lastLogin!)}',
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) {
                                    if (v == 'role') _toggleRole(u);
                                    if (v == 'delete') _deleteUser(u);
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'role',
                                      child: Row(children: [
                                        Icon(
                                          u.isAdmin
                                              ? Icons.person_rounded
                                              : Icons.admin_panel_settings_rounded,
                                          size: 18,
                                          color: AppTheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(u.isAdmin
                                            ? 'Hạ xuống User' : 'Nâng lên Admin'),
                                      ]),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(children: [
                                        Icon(Icons.delete_outline_rounded,
                                            size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Xóa tài khoản',
                                            style: TextStyle(color: Colors.red)),
                                      ]),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
