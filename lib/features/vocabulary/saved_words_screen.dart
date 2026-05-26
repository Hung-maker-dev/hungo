// lib/features/vocabulary/saved_words_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/vocabulary_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class SavedWordsScreen extends StatefulWidget {
  const SavedWordsScreen({super.key});
  @override
  State<SavedWordsScreen> createState() => _SavedWordsScreenState();
}

class _SavedWordsScreenState extends State<SavedWordsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        context.read<VocabularyProvider>().loadSavedWords(auth.currentUser!.id!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VocabularyProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Từ đã lưu (${vp.savedWords.length})'),
        actions: [
          if (vp.savedWords.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.style_rounded),
              tooltip: 'Học với bộ thẻ',
              onPressed: () {
                for (final w in vp.savedWords) {
                  if (!vp.flashcardDeck.any((d) => d.word == w.word)) {
                    vp.flashcardDeck.insert(0, w);
                  }
                }
                Navigator.pushNamed(context, '/vocab/flashcard');
              },
            ),
        ],
      ),
      body: !auth.isLoggedIn
          ? const Center(child: Text('Đăng nhập để xem từ đã lưu'))
          : vp.savedWords.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.bookmark_outline, size: 72, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text('Chưa có từ nào được lưu'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tìm từ mới'),
                    ),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vp.savedWords.length,
                  itemBuilder: (_, i) {
                    final v = vp.savedWords[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(children: [
                          Text(v.word,
                              style: const TextStyle(fontWeight: FontWeight.bold,
                                  fontSize: 17, color: AppTheme.primary)),
                          const SizedBox(width: 8),
                          if (v.partOfSpeech != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(v.partOfSpeech!,
                                  style: const TextStyle(fontSize: 11, color: AppTheme.primary)),
                            ),
                        ]),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (v.phonetic != null)
                              Text(v.phonetic!, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(v.definition, maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.bookmark_rounded, color: AppTheme.primary),
                          onPressed: () => vp.toggleSaveWord(v, auth.currentUser!.id!),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
