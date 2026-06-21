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

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();
  final _tts   = FlutterTts();
  List<String> _suggestions = [];
  late TabController _tab;

  static const _primary = AppTheme.primary; // blue 800

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.5);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VocabularyProvider>().loadRandomWords();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose(); _focus.dispose(); _tts.stop(); _tab.dispose();
    super.dispose();
  }

  Future<void> _search(String word) async {
    if (word.trim().isEmpty) return;
    _focus.unfocus();
    setState(() => _suggestions = []);
    final auth = context.read<AuthProvider>();
    await context.read<VocabularyProvider>()
        .searchWord(word.trim(), userId: auth.currentUser?.id);
    _tab.animateTo(0);
  }

  Future<void> _onChanged(String v) async {
    if (v.length < 2) { setState(() => _suggestions = []); return; }
    final s = await context.read<VocabularyProvider>().getSuggestions(v);
    if (mounted) setState(() => _suggestions = s);
  }

  @override
  Widget build(BuildContext context) {
    final vp   = context.watch<VocabularyProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (auth.isLoggedIn)
                IconButton(
                  icon: const Icon(Icons.bookmark_rounded),
                  onPressed: () => Navigator.pushNamed(context, '/vocab/saved'),
                  tooltip: 'Từ đã lưu',
                ),
              IconButton(
                icon: const Icon(Icons.quiz_rounded),
                onPressed: () => Navigator.pushNamed(context, '/vocab/quiz'),
                tooltip: 'Trắc nghiệm',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 56),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Từ điển',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  SizedBox(height: 2),
                  Text('Tra từ • Khám phá • Học từ vựng',
                      style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
              background: Stack(children: [
                // Gradient nền
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _primary,
                        const Color(0xFF1976D2),
                        const Color(0xFF42A5F5).withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
                // Decoration circles
                Positioned(right: -30, top: -20,
                  child: Container(width: 130, height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                    ))),
                Positioned(right: 60, bottom: 10,
                  child: Container(width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ))),
                // Icon trang trí
                const Positioned(right: 16, top: 20,
                  child: Icon(Icons.menu_book_rounded,
                      size: 60, color: Colors.white12)),
              ]),
            ),
            // ── Tab bar nằm ở bottom của AppBar ──────────────────────────
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: _primary,
                  unselectedLabelColor: Colors.white,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontSize: 12),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: '🔍  Tra từ'),
                    Tab(text: '🎲  Từ ngẫu nhiên'),
                  ],
                ),
              ),
            ),
          ),
        ],

        body: Column(children: [
          // ── Search bar ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(children: [
              Row(children: [
                Expanded(child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  textInputAction: TextInputAction.search,
                  onChanged: _onChanged,
                  onSubmitted: _search,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Nhập từ tiếng Anh...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: _primary),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: _primary, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    suffixIcon: _ctrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: Colors.grey),
                            onPressed: () {
                              _ctrl.clear();
                              setState(() => _suggestions = []);
                              vp.clearResult();
                            })
                        : null,
                  ),
                )),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _search(_ctrl.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text('Tra',
                        style: TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
            ]),
          ),

          // ── Suggestions dropdown ──────────────────────────────────────
          if (_suggestions.isNotEmpty)
            Container(
              color: Colors.white,
              child: Column(
                children: _suggestions.take(5).map((s) => InkWell(
                  onTap: () { _ctrl.text = s; _search(s); },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(children: [
                      Icon(Icons.history_rounded,
                          size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 10),
                      Text(s, style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      Icon(Icons.north_west_rounded,
                          size: 14, color: Colors.grey.shade400),
                    ]),
                  ),
                )).toList(),
              ),
            ),

          // ── Tab content ───────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _SearchResultTab(vp: vp, auth: auth, tts: _tts),
                _RandomWordsTab(vp: vp, auth: auth, tts: _tts),
              ],
            ),
          ),
        ]),
      ),

      // FAB bộ thẻ
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/vocab/flashcard'),
        icon: const Icon(Icons.style_rounded),
        label: const Text('Bộ thẻ'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
    );
  }
}

// ── Tab kết quả tìm kiếm ────────────────────────────────────────────────────

class _SearchResultTab extends StatelessWidget {
  final VocabularyProvider vp;
  final AuthProvider auth;
  final FlutterTts tts;
  const _SearchResultTab({required this.vp, required this.auth, required this.tts});

  @override
  Widget build(BuildContext context) {
    if (vp.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vp.errorMessage != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(vp.errorMessage!,
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center),
        ]),
      ));
    }
    if (vp.searchResult == null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.08),
            ),
            child: const Icon(Icons.translate_rounded,
                size: 52, color: AppTheme.primary),
          ),
          const SizedBox(height: 20),
          const Text('Nhập từ cần tra ở thanh tìm kiếm',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Hỗ trợ tiếng Anh, có phiên âm và nghĩa tiếng Việt',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              textAlign: TextAlign.center),
        ]),
      ));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _WordCard(word: vp.searchResult!, auth: auth, tts: tts, vp: vp),
    );
  }
}

// ── Tab từ ngẫu nhiên ────────────────────────────────────────────────────────

class _RandomWordsTab extends StatelessWidget {
  final VocabularyProvider vp;
  final AuthProvider auth;
  final FlutterTts tts;
  const _RandomWordsTab({required this.vp, required this.auth, required this.tts});

  @override
  Widget build(BuildContext context) {
    final words = vp.randomWords;
    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        color: Colors.white,
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Từ vựng hôm nay',
                  style: TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Text('Khám phá và học từ mới mỗi ngày',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          )),
          TextButton.icon(
            onPressed: () => context.read<VocabularyProvider>().loadRandomWords(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Làm mới', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
          ),
        ]),
      ),

      if (vp.isLoading)
        const Expanded(child: Center(child: CircularProgressIndicator()))
      else if (words.isEmpty)
        Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.library_books_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Chưa có từ vựng trong kho',
              style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text('Admin cần thêm từ vựng trước',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ])))
      else
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: words.length,
          itemBuilder: (_, i) => _RandomWordTile(
              word: words[i], auth: auth, tts: tts, vp: vp),
        )),
    ]);
  }
}

// ── Random word tile ──────────────────────────────────────────────────────────

class _RandomWordTile extends StatelessWidget {
  final VocabularyModel word;
  final AuthProvider auth;
  final FlutterTts tts;
  final VocabularyProvider vp;
  const _RandomWordTile({required this.word, required this.auth,
      required this.tts, required this.vp});

  static const _levelColors = {
    'A1': Color(0xFF43A047), 'A2': Color(0xFF1E88E5),
    'B1': Color(0xFFF9A825), 'B2': Color(0xFFEF6C00),
    'C1': Color(0xFFE53935), 'C2': Color(0xFF7B1FA2),
  };

  @override
  Widget build(BuildContext context) {
    final lvlColor = _levelColors[word.level] ?? AppTheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Level badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: lvlColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(word.level, style: TextStyle(
                  fontSize: 11, color: lvlColor,
                  fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(word.word, style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 17)),
                if (word.phonetic != null)
                  Text(word.phonetic!, style: TextStyle(
                      color: Colors.grey.shade500, fontSize: 12,
                      fontStyle: FontStyle.italic)),
              ],
            )),
            // Actions
            IconButton(
              icon: Icon(Icons.volume_up_rounded,
                  color: AppTheme.primary.withValues(alpha: 0.8), size: 22),
              onPressed: () => tts.speak(word.word),
              tooltip: 'Phát âm',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            if (auth.isLoggedIn)
              IconButton(
                icon: Icon(
                  word.isSaved ? Icons.bookmark_rounded
                      : Icons.bookmark_outline_rounded,
                  color: word.isSaved ? Colors.amber.shade600 : Colors.grey,
                  size: 22),
                onPressed: () => vp.toggleSaveWord(word, auth.currentUser!.id!),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
          ]),

          const SizedBox(height: 8),

          // Loại từ
          if (word.partOfSpeech != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(word.partOfSpeech!,
                  style: const TextStyle(color: AppTheme.primary,
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
          ],

          // Nghĩa EN
          Text(word.definition,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800,
                  height: 1.4)),

          // Nghĩa VI
          if (word.definitionVi != null) ...[
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('🇻🇳 ', style: const TextStyle(fontSize: 12)),
              Expanded(child: Text(word.definitionVi!,
                  style: TextStyle(color: Colors.blue.shade700,
                      fontSize: 13, fontWeight: FontWeight.w500))),
            ]),
          ],

          // Ví dụ
          if (word.example != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Icon(Icons.format_quote_rounded,
                    size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Expanded(child: Text(word.example!,
                    style: TextStyle(color: Colors.grey.shade600,
                        fontSize: 12, fontStyle: FontStyle.italic,
                        height: 1.4))),
              ]),
            ),
          ],

          if (word.topic != null) ...[
            const SizedBox(height: 6),
            Text('#${word.topic}',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
          ],
        ]),
      ),
    );
  }
}

// ── Word detail card (kết quả tra từ) ────────────────────────────────────────

class _WordCard extends StatelessWidget {
  final VocabularyModel word;
  final AuthProvider auth;
  final FlutterTts tts;
  final VocabularyProvider vp;
  const _WordCard({required this.word, required this.auth,
      required this.tts, required this.vp});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header card
      Card(
        elevation: 2,
        shadowColor: Colors.blue.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primary,
                const Color(0xFF1976D2),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(word.word, style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.bold,
                    color: Colors.white, letterSpacing: 0.5)),
                if (word.phonetic != null) ...[
                  const SizedBox(height: 4),
                  Text(word.phonetic!, style: const TextStyle(
                      color: Colors.white70, fontSize: 16,
                      fontStyle: FontStyle.italic)),
                ],
                if (word.partOfSpeech != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(word.partOfSpeech!,
                        style: const TextStyle(color: Colors.white,
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            )),
            Column(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.volume_up_rounded,
                      color: Colors.white, size: 24),
                  onPressed: () => tts.speak(word.word),
                  tooltip: 'Phát âm',
                ),
              ),
              if (auth.isLoggedIn) ...[
                const SizedBox(height: 8),
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      word.isSaved ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      color: word.isSaved ? Colors.amber : Colors.white,
                      size: 22),
                    onPressed: () =>
                        vp.toggleSaveWord(word, auth.currentUser!.id!),
                  ),
                ),
              ],
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 12),

      // Nghĩa & chi tiết
      Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // EN definition
            _DefRow(
              icon: Icons.language_rounded,
              iconColor: Colors.blue.shade600,
              label: 'Nghĩa (EN)',
              value: word.definition,
            ),

            if (word.definitionVi != null) ...[
              const Divider(height: 20),
              _DefRow(
                icon: Icons.translate_rounded,
                iconColor: Colors.red.shade400,
                label: 'Nghĩa (VI)',
                value: word.definitionVi!,
                valueColor: Colors.blue.shade700,
              ),
            ],

            if (word.example != null) ...[
              const Divider(height: 20),
              _DefRow(
                icon: Icons.format_quote_rounded,
                iconColor: Colors.green.shade600,
                label: 'Ví dụ',
                value: word.example!,
                isItalic: true,
              ),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 12),

      // Tags
      Row(children: [
        _TagChip(word.level, Colors.green),
        if (word.topic != null) ...[
          const SizedBox(width: 8),
          _TagChip('#${word.topic}', Colors.blue),
        ],
      ]),
      const SizedBox(height: 80),
    ]);
  }
}

class _DefRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label, value;
  final Color? valueColor;
  final bool isItalic;
  const _DefRow({required this.icon, required this.iconColor,
      required this.label, required this.value,
      this.valueColor, this.isItalic = false});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(
              fontSize: 11, color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(
              fontSize: 15, height: 1.5,
              color: valueColor ?? Colors.grey.shade800,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal)),
        ],
      )),
    ],
  );
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TagChip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(label, style: TextStyle(color: color,
        fontSize: 12, fontWeight: FontWeight.w600)),
  );
}
