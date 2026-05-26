// lib/features/vocabulary/search_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/providers/vocabulary_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  final _tts = FlutterTts();
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.5);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _search(String word) async {
    if (word.trim().isEmpty) return;
    _focus.unfocus();
    setState(() => _suggestions = []);
    final auth = context.read<AuthProvider>();
    await context.read<VocabularyProvider>()
        .searchWord(word.trim(), userId: auth.currentUser?.id);
  }

  Future<void> _onChanged(String v) async {
    if (v.length < 2) { setState(() => _suggestions = []); return; }
    final s = await context.read<VocabularyProvider>().getSuggestions(v);
    if (mounted) setState(() => _suggestions = s);
  }

  Future<void> _speak(String word) async {
    await _tts.speak(word);
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VocabularyProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Từ điển'),
        actions: [
          if (auth.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.bookmark_outline_rounded),
              onPressed: () => Navigator.pushNamed(context, '/vocab/saved'),
              tooltip: 'Từ đã lưu',
            ),
          IconButton(
            icon: const Icon(Icons.quiz_outlined),
            onPressed: () => Navigator.pushNamed(context, '/vocab/quiz'),
            tooltip: 'Trắc nghiệm',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────────
          Container(
            color: AppTheme.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              onChanged: _onChanged,
              onSubmitted: _search,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Nhập từ tiếng Anh...',
                hintStyle: const TextStyle(color: Colors.white60),
                fillColor: Colors.white24,
                filled: true,
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _suggestions = []);
                        })
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── Suggestions ──────────────────────────────────────────────────
          if (_suggestions.isNotEmpty)
            Container(
              color: Theme.of(context).cardColor,
              child: Column(
                children: _suggestions.map((s) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.history_rounded, size: 18),
                  title: Text(s),
                  onTap: () {
                    _ctrl.text = s;
                    _search(s);
                  },
                )).toList(),
              ),
            ),

          Expanded(
            child: vp.isSearching
                ? const Center(child: CircularProgressIndicator())
                : vp.error != null
                    ? _ErrorWidget(message: vp.error!)
                    : vp.searchResults.isEmpty
                        ? _EmptyState(history: vp.searchHistory, onTap: (w) {
                            _ctrl.text = w;
                            _search(w);
                          })
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Kết quả mới nhất
                              _WordCard(
                                vocab: vp.searchResults.first,
                                onSpeak: _speak,
                                onSave: auth.isLoggedIn
                                    ? () => vp.toggleSaveWord(
                                        vp.searchResults.first,
                                        auth.currentUser!.id!)
                                    : null,
                                onAddDeck: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã thêm "${vp.searchResults.first.word}" vào bộ thẻ!'),
                                      backgroundColor: AppTheme.success,
                                      action: SnackBarAction(
                                        label: 'Xem thẻ',
                                        textColor: Colors.white,
                                        onPressed: () => Navigator.pushNamed(context, '/vocab/flashcard'),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              // Lịch sử tìm kiếm
                              if (vp.searchResults.length > 1) ...[
                                const Text('Đã tìm trước đó',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                const SizedBox(height: 8),
                                ...vp.searchResults.skip(1).map((v) =>
                                    _MiniWordTile(vocab: v, onTap: () {
                                      _ctrl.text = v.word;
                                      _search(v.word);
                                    })),
                              ],
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Word Card Widget ──────────────────────────────────────────────────────────
class _WordCard extends StatelessWidget {
  final VocabularyModel vocab;
  final Future<void> Function(String) onSpeak;
  final VoidCallback? onSave;
  final VoidCallback onAddDeck;

  const _WordCard({required this.vocab, required this.onSpeak,
      this.onSave, required this.onAddDeck});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word + save button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vocab.word,
                          style: theme.textTheme.displayMedium?.copyWith(
                              color: AppTheme.primary, fontWeight: FontWeight.bold)),
                      if (vocab.phonetic != null)
                        Text(vocab.phonetic!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                // Speak button
                IconButton(
                  onPressed: () => onSpeak(vocab.word),
                  icon: const Icon(Icons.volume_up_rounded, color: AppTheme.primary, size: 28),
                  tooltip: 'Nghe phát âm',
                ),
                // Save button
                if (onSave != null)
                  IconButton(
                    onPressed: onSave,
                    icon: Icon(
                      vocab.isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      color: vocab.isSaved ? AppTheme.primary : Colors.grey,
                      size: 28,
                    ),
                    tooltip: vocab.isSaved ? 'Bỏ lưu' : 'Lưu từ',
                  ),
              ],
            ),
            const Divider(height: 24),

            // Part of speech badge
            if (vocab.partOfSpeech != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(vocab.partOfSpeech!,
                    style: const TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
              const SizedBox(height: 12),
            ],

            // Definition
            Text('Định nghĩa', style: TextStyle(
                color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(vocab.definition, style: theme.textTheme.bodyLarge),

            // Dịch nghĩa tiếng Việt nếu có
            if (vocab.definitionVi != null) ...[
              const SizedBox(height: 8),
              Text('🇻🇳 ${vocab.definitionVi}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
            ],

            // Example
            if (vocab.example != null) ...[
              const SizedBox(height: 12),
              Text('Ví dụ', style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                ),
                child: Text('"${vocab.example}"',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic)),
              ),
            ],

            const SizedBox(height: 16),
            // Add to deck button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAddDeck,
                icon: const Icon(Icons.style_rounded),
                label: const Text('Thêm vào bộ thẻ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniWordTile extends StatelessWidget {
  final VocabularyModel vocab;
  final VoidCallback onTap;
  const _MiniWordTile({required this.vocab, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: const Icon(Icons.history_rounded, color: AppTheme.primary),
      title: Text(vocab.word, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(vocab.definition, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final List<String> history;
  final void Function(String) onTap;
  const _EmptyState({required this.history, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Icon(Icons.search_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Tìm kiếm từ vựng tiếng Anh',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Nhập từ bất kỳ để tra nghĩa, phát âm và lưu vào bộ thẻ',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600)),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Tìm kiếm gần đây',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: history.map((w) => ActionChip(
                label: Text(w),
                avatar: const Icon(Icons.history_rounded, size: 16),
                onPressed: () => onTap(w),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final String message;
  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
        ]),
      ),
    );
  }
}
