// lib/features/main/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../vocabulary/search_screen.dart';
import '../grammar/grammar_list_screen.dart';
import '../reading/reading_list_screen.dart';
import '../listening/listening_list_screen.dart';
import '../profile/profile_screen.dart';
import '../roadmap/roadmap_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _idx = 0;

  static const _tabs = [
    _TabItem(Icons.search_rounded, Icons.search_rounded, 'Từ vựng'),
    _TabItem(Icons.edit_note_rounded, Icons.edit_note_rounded, 'Ngữ pháp'),
    _TabItem(Icons.route_outlined, Icons.route_rounded, 'Lộ trình'),
    _TabItem(Icons.chrome_reader_mode_outlined, Icons.chrome_reader_mode_rounded, 'Đọc'),
    _TabItem(Icons.headphones_outlined, Icons.headphones_rounded, 'Nghe'),
    _TabItem(Icons.person_outline_rounded, Icons.person_rounded, 'Hồ sơ'),
  ];

  // Tab yêu cầu login
  static const _requireLogin = {1, 2, 3, 4, 5};

  void _onTap(int i, BuildContext ctx) {
    if (_requireLogin.contains(i)) {
      final auth = ctx.read<AuthProvider>();
      if (!auth.isLoggedIn) {
        _showLoginDialog(ctx);
        return;
      }
    }
    setState(() => _idx = i);
  }

  void _showLoginDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.lock_outline, color: AppTheme.primary),
          SizedBox(width: 8),
          Text('Yêu cầu đăng nhập'),
        ]),
        content: const Text('Tính năng này cần đăng nhập. Bạn muốn đăng nhập ngay?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Để sau')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(ctx, '/login');
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: IndexedStack(
        index: _idx,
        children: const [
          SearchScreen(),        // 0 - Từ vựng
          GrammarListScreen(),   // 1 - Ngữ pháp
          RoadmapScreen(),       // 2 - Lộ trình
          ReadingListScreen(),   // 3 - Đọc
          ListeningListScreen(), // 5 - Nghe ← SỬA LẠI: Từ vị trí 4 lên 5
          ProfileScreen(),       // 4 - Hồ sơ ← SỬA LẠI: Từ vị trí 5 xuống
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => _onTap(i, context),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: List.generate(_tabs.length, (i) {
          final t = _tabs[i];
          final locked = _requireLogin.contains(i) && !auth.isLoggedIn;
          return NavigationDestination(
            icon: Icon(t.icon),
            selectedIcon: Icon(t.selectedIcon),
            label: locked ? '🔒 ${t.label}' : t.label,
          );
        }),
      ),
      // FAB chỉ hiện ở tab Flashcard
      floatingActionButton: _idx == 0
          ? FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/vocab/flashcard'),
        icon: const Icon(Icons.style_rounded),
        label: const Text('Bộ thẻ'),
        backgroundColor: AppTheme.primary,
      )
          : null,
    );
  }
}

class _TabItem {
  final IconData icon, selectedIcon;
  final String label;
  const _TabItem(this.icon, this.selectedIcon, this.label);
}