// lib/features/grammar/grammar_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/grammar_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class GrammarListScreen extends StatefulWidget {
  const GrammarListScreen({super.key});
  @override
  State<GrammarListScreen> createState() => _GrammarListScreenState();
}

class _GrammarListScreenState extends State<GrammarListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _cats = ['present', 'past', 'future'];
  final _catNames = {'present': 'Hiện tại', 'past': 'Quá khứ', 'future': 'Tương lai'};

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GrammarProvider>().loadTopics();
    });
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GrammarProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ngữ pháp'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: _cats.map((c) => Tab(text: _catNames[c])).toList(),
        ),
      ),
      body: !auth.isLoggedIn
          ? _LoginPrompt()
          : gp.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tab,
                  children: _cats.map((cat) {
                    final topics = gp.byCategory(cat);
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: topics.length,
                      itemBuilder: (_, i) => _GrammarTile(
                        topic: topics[i],
                        index: i,
                        onTap: () => Navigator.pushNamed(
                          context, '/grammar/detail',
                          arguments: topics[i],
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}

class _GrammarTile extends StatelessWidget {
  final GrammarTopic topic;
  final int index;
  final VoidCallback onTap;
  const _GrammarTile({required this.topic, required this.index, required this.onTap});

  static const _catColors = {
    'present': AppTheme.skillGrammar,
    'past': AppTheme.skillReading,
    'future': AppTheme.skillListening,
  };

  @override
  Widget build(BuildContext context) {
    final color = _catColors[topic.category] ?? AppTheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('${index + 1}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(topic.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (topic.nameVi != null)
                  Text(topic.nameVi!,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                if (topic.formula != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(topic.formula!,
                        style: TextStyle(color: color, fontSize: 12,
                            fontFamily: 'monospace', fontWeight: FontWeight.w500)),
                  ),
                ],
              ]),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_outline_rounded, size: 72, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('Đăng nhập để học ngữ pháp',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Tính năng này yêu cầu tài khoản',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('Đăng nhập ngay'),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            child: const Text('Tạo tài khoản miễn phí'),
          ),
        ]),
      ),
    );
  }
}
