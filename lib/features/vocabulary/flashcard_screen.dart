// lib/features/vocabulary/flashcard_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/providers/vocabulary_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});
  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with TickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isFlipped = false;
  final _tts = FlutterTts();
  late PageController _pageCtrl;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnim = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
    _pageCtrl = PageController();
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.45);
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _pageCtrl.dispose();
    _tts.stop();
    super.dispose();
  }

  void _flip() {
    setState(() => _isFlipped = !_isFlipped);
    _isFlipped ? _flipCtrl.forward() : _flipCtrl.reverse();
  }

  void _next(VocabularyProvider vp) {
    if (_current < vp.flashcardDeck.length - 1) {
      setState(() { _current++; _isFlipped = false; });
      _flipCtrl.reverse();
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prev(VocabularyProvider vp) {
    if (_current > 0) {
      setState(() { _current--; _isFlipped = false; });
      _flipCtrl.reverse();
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VocabularyProvider>();
    final auth = context.watch<AuthProvider>();
    final deck = vp.flashcardDeck;

    return Scaffold(
      appBar: AppBar(
        title: deck.isEmpty ? const Text('Bộ thẻ') :
            Text('${_current + 1} / ${deck.length}'),
        actions: [
          if (deck.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, vp),
              tooltip: 'Xóa tất cả',
            ),
        ],
      ),
      body: deck.isEmpty
          ? _EmptyDeck(onSearch: () => Navigator.pop(context))
          : Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: ((_current + 1) / deck.length),
                  backgroundColor: Colors.grey.shade200,
                  color: AppTheme.primary,
                  minHeight: 4,
                ),

                // Card area
                Expanded(
                  child: PageView.builder(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: deck.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: GestureDetector(
                        onTap: _flip,
                        child: _FlipCard(
                          anim: _flipAnim,
                          vocab: deck[i],
                          isFlipped: _isFlipped,
                          onSpeak: () => _tts.speak(deck[i].word),
                        ),
                      ),
                    ),
                  ),
                ),

                // Hint
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Nhấn vào thẻ để lật',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ),

                // Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      // Không biết
                      Expanded(
                        child: _ActionBtn(
                          label: 'Chưa biết',
                          icon: Icons.close_rounded,
                          color: Colors.red.shade400,
                          onTap: () {
                            vp.removeFromDeck(_current);
                            if (_current > 0 && _current >= vp.flashcardDeck.length) {
                              setState(() { _current--; _isFlipped = false; });
                            } else {
                              setState(() => _isFlipped = false);
                              _flipCtrl.reverse();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nghe phát âm
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        child: IconButton(
                          icon: const Icon(Icons.volume_up_rounded, color: AppTheme.primary),
                          onPressed: () => _tts.speak(deck[_current].word),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Đã biết
                      Expanded(
                        child: _ActionBtn(
                          label: 'Đã biết',
                          icon: Icons.check_rounded,
                          color: Colors.green.shade500,
                          onTap: () {
                            // Nếu login: lưu từ
                            if (auth.isLoggedIn) {
                              vp.toggleSaveWord(deck[_current], auth.currentUser!.id!);
                            }
                            _next(vp);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Prev / Next
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _current > 0 ? () => _prev(vp) : null,
                        icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                        label: const Text('Trước'),
                      ),
                      // Dots indicator
                      Row(
                        children: List.generate(
                          deck.length > 7 ? 7 : deck.length,
                          (i) {
                            final idx = deck.length > 7 ? (_current - 3 + i).clamp(0, deck.length - 1) : i;
                            return Container(
                              width: idx == _current ? 20 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: idx == _current ? AppTheme.primary : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          },
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _current < deck.length - 1 ? () => _next(vp) : null,
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        label: const Text('Tiếp'),
                        iconAlignment: IconAlignment.end,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _confirmClear(BuildContext ctx, VocabularyProvider vp) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Xóa bộ thẻ?'),
        content: const Text('Bạn có chắc muốn xóa tất cả thẻ trong bộ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () { vp.clearDeck(); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _FlipCard extends StatelessWidget {
  final Animation<double> anim;
  final VocabularyModel vocab;
  final bool isFlipped;
  final VoidCallback onSpeak;

  const _FlipCard({required this.anim, required this.vocab,
      required this.isFlipped, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final angle = anim.value * pi;
        final showFront = angle <= pi / 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: showFront ? _CardFace(vocab: vocab, isFront: true, onSpeak: onSpeak)
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(pi),
                  child: _CardFace(vocab: vocab, isFront: false, onSpeak: onSpeak),
                ),
        );
      },
    );
  }
}

class _CardFace extends StatelessWidget {
  final VocabularyModel vocab;
  final bool isFront;
  final VoidCallback onSpeak;
  const _CardFace({required this.vocab, required this.isFront, required this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isFront
                ? [AppTheme.primary, AppTheme.primaryDark]
                : [Colors.white, const Color(0xFFF0F4FF)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isFront) ...[
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Từ tiếng Anh',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
                const SizedBox(height: 24),
                Text(vocab.word,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 40,
                        fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    textAlign: TextAlign.center),
                if (vocab.phonetic != null) ...[
                  const SizedBox(height: 8),
                  Text(vocab.phonetic!,
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                      textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: onSpeak,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white24, shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Nhấn để xem nghĩa',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Nghĩa & Ví dụ',
                      style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                ),
                const SizedBox(height: 16),
                if (vocab.partOfSpeech != null)
                  Text('[${vocab.partOfSpeech}]',
                      style: const TextStyle(color: AppTheme.primaryLight, fontSize: 14),
                      textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(vocab.definition,
                    style: TextStyle(
                        color: Colors.grey.shade800, fontSize: 18,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
                if (vocab.definitionVi != null) ...[
                  const SizedBox(height: 8),
                  Text('🇻🇳 ${vocab.definitionVi}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                      textAlign: TextAlign.center),
                ],
                if (vocab.example != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('"${vocab.example}"',
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 14,
                            fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _EmptyDeck extends StatelessWidget {
  final VoidCallback onSearch;
  const _EmptyDeck({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.style_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Bộ thẻ trống', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Tìm kiếm từ vựng và nhấn "Thêm vào bộ thẻ" để bắt đầu',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Tìm từ vựng'),
          ),
        ]),
      ),
    );
  }
}
