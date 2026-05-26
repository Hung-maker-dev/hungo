// lib/features/profile/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          const _SectionHeader('Giao diện'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              // Light/Dark toggle
              SwitchListTile(
                value: tp.isDark,
                onChanged: (_) => tp.toggleTheme(),
                title: const Text('Chế độ tối'),
                subtitle: Text(tp.isDark ? 'Dark mode đang bật' : 'Light mode đang bật'),
                secondary: Icon(tp.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: AppTheme.primary),
              ),
              const Divider(height: 1, indent: 56),
              // Theme mode options
              ListTile(
                leading: const Icon(Icons.phone_android_rounded, color: AppTheme.primary),
                title: const Text('Theo hệ thống'),
                trailing: tp.themeMode == ThemeMode.system
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary) : null,
                onTap: () => tp.setTheme(ThemeMode.system),
              ),
              ListTile(
                leading: const Icon(Icons.light_mode_rounded, color: Colors.amber),
                title: const Text('Sáng'),
                trailing: tp.themeMode == ThemeMode.light
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary) : null,
                onTap: () => tp.setTheme(ThemeMode.light),
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_rounded, color: Colors.indigo),
                title: const Text('Tối'),
                trailing: tp.themeMode == ThemeMode.dark
                    ? const Icon(Icons.check_rounded, color: AppTheme.primary) : null,
                onTap: () => tp.setTheme(ThemeMode.dark),
              ),
            ]),
          ),

          const _SectionHeader('Tài khoản'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              if (auth.isLoggedIn) ...[
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: AppTheme.primary),
                  title: const Text('Thông tin cá nhân'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  subtitle: Text(auth.currentUser!.username),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded, color: AppTheme.primary),
                  title: const Text('Đổi mật khẩu'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => _showChangePassword(context),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Colors.red),
                  title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.login_rounded, color: AppTheme.primary),
                  title: const Text('Đăng nhập'),
                  onTap: () => Navigator.pushNamed(context, '/login'),
                ),
              ],
            ]),
          ),

          const _SectionHeader('Thông tin'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              const ListTile(
                leading: Icon(Icons.info_outline_rounded, color: AppTheme.primary),
                title: Text('Phiên bản'),
                trailing: Text('1.0.0', style: TextStyle(color: Colors.grey)),
              ),
              const Divider(height: 1, indent: 56),
              const ListTile(
                leading: Icon(Icons.menu_book_rounded, color: AppTheme.primary),
                title: Text('Hungo'),
                subtitle: Text('App học tiếng Anh toàn diện'),
              ),
            ]),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext ctx) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đổi mật khẩu'),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: oldCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu cũ'),
              validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: newCtrl, obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
              validator: (v) => v!.length < 6 ? 'Tối thiểu 6 ký tự' : null,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final err = await ctx.read<AuthProvider>().changePassword(
                oldPassword: oldCtrl.text, newPassword: newCtrl.text,
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(err ?? 'Đổi mật khẩu thành công!'),
                  backgroundColor: err != null ? Colors.red : Colors.green,
                ));
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(title.toUpperCase(),
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold,
              color: Colors.grey.shade500, letterSpacing: 1.2)),
    );
  }
}
