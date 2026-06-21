// lib/features/grammar/grammar_detail_screen.dart
import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class GrammarDetailScreen extends StatelessWidget {
  final dynamic topic;
  const GrammarDetailScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final t = topic as GrammarTopic;
    final signals =
        t.signalWords?.split(',').map((s) => s.trim()).toList() ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // SliverAppBar (đã fix lỗi chèn chữ)
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final isCollapsed =
                    constraints.biggest.height <= kToolbarHeight + 20;

                return FlexibleSpaceBar(
                  title: isCollapsed
                      ? Text(
                    t.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  )
                      : null,
                  centerTitle: false,
                  collapseMode: CollapseMode.pin,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary,
                          AppTheme.primaryDark
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding:
                      const EdgeInsets.fromLTRB(20, 60, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (t.nameVi != null)
                            Text(
                              t.nameVi!,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 15),
                            ),
                          if (t.formula != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t.formula!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lý thuyết
                  _Section(
                    title: '📖 Lý thuyết',
                    child: Text(
                      t.theory.replaceAll('##', '').trim(),
                      style: const TextStyle(fontSize: 15, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Signal words
                  if (signals.isNotEmpty)
                    _Section(
                      title: '🔑 Từ tín hiệu nhận biết',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: signals
                            .map(
                              (s) => Chip(
                            label: Text(s),
                            backgroundColor:
                            AppTheme.primary.withOpacity(0.08),
                            labelStyle: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w500),
                            side: const BorderSide(
                                color: AppTheme.primary, width: 0.5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4),
                          ),
                        )
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Ví dụ
                  _Section(
                    title: '📝 Ví dụ',
                    child: Column(
                      children: [
                        if (t.examplePos != null)
                          _ExampleRow(
                              label: '(+)',
                              text: t.examplePos!,
                              color: Colors.green),
                        if (t.exampleNeg != null)
                          _ExampleRow(
                              label: '(-)',
                              text: t.exampleNeg!,
                              color: Colors.red),
                        if (t.exampleQue != null)
                          _ExampleRow(
                              label: '(?)',
                              text: t.exampleQue!,
                              color: Colors.blue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/grammar/exercise',
                        arguments: {
                          'grammarTopic': t.name,
                          'grammarName': t.name,
                        },
                      ),
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Làm bài tập'),
                      style: ElevatedButton.styleFrom(
                        padding:
                        const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child,
        ]);
  }
}

class _ExampleRow extends StatelessWidget {
  final String label, text;
  final Color color;
  const _ExampleRow(
      {required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(label,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, fontSize: 14)),
            ),
          ]),
    );
  }
}