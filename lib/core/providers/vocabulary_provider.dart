// lib/core/providers/vocabulary_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/models.dart';

class VocabularyProvider extends ChangeNotifier {
  List<VocabularyModel> _searchResults = [];
  List<VocabularyModel> _savedWords    = [];
  List<VocabularyModel> _flashcardDeck = [];
  List<String>          _searchHistory = [];
  bool   _isSearching = false;
  String? _error;
  String  _searchQuery = '';
  int    _currentCardIndex = 0;

  List<VocabularyModel> get searchResults  => _searchResults;
  List<VocabularyModel> get savedWords     => _savedWords;
  List<VocabularyModel> get flashcardDeck  => _flashcardDeck;
  List<String>          get searchHistory  => _searchHistory;
  bool   get isSearching   => _isSearching;
  String? get error        => _error;
  String  get searchQuery  => _searchQuery;
  int    get currentCardIndex => _currentCardIndex;
  VocabularyModel? get currentCard =>
      _flashcardDeck.isNotEmpty ? _flashcardDeck[_currentCardIndex] : null;

  static const _dictApi = 'https://api.dictionaryapi.dev/api/v2/entries/en';
  static const _translateApi = 'https://api.mymemory.translated.net/get';

  // ── Dịch sang tiếng Việt qua MyMemory API ────────────────────────────────
  Future<String?> _translateToVi(String text) async {
    if (text.trim().isEmpty) return null;
    try {
      // Giới hạn độ dài để tránh lỗi API
      final shortText = text.length > 200 ? '${text.substring(0, 200)}...' : text;
      final encoded = Uri.encodeComponent(shortText);
      final res = await http.get(
        Uri.parse('$_translateApi?q=$encoded&langpair=en|vi'),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final translated = data['responseData']?['translatedText'] as String?;
        // MyMemory trả về lỗi dưới dạng text "MYMEMORY WARNING" nếu hết quota
        if (translated != null && !translated.toUpperCase().contains('MYMEMORY')) {
          return translated;
        }
      }
    } catch (_) {}
    return null;
  }

  // ── Search từ chính ───────────────────────────────────────────────────────
  Future<VocabularyModel?> searchWord(String word, {int? userId}) async {
    if (word.trim().isEmpty) return null;
    _isSearching = true;
    _error = null;
    _searchQuery = word.trim().toLowerCase();
    notifyListeners();

    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Kiểm tra cache local SQLite trước
      final local = await db.query(
        'vocabulary',
        where: 'LOWER(word) = ?',
        whereArgs: [_searchQuery],
        limit: 1,
      );

      VocabularyModel vocab;

      if (local.isNotEmpty) {
        vocab = VocabularyModel.fromMap(local.first);

        // Nếu chưa có nghĩa tiếng Việt → dịch và cập nhật cache
        if (vocab.definitionVi == null || vocab.definitionVi!.isEmpty) {
          final vi = await _translateToVi(vocab.definition);
          if (vi != null) {
            await db.update(
              'vocabulary',
              {'definition_vi': vi},
              where: 'id = ?',
              whereArgs: [vocab.id],
            );
            vocab = VocabularyModel(
              id: vocab.id,
              word: vocab.word,
              phonetic: vocab.phonetic,
              partOfSpeech: vocab.partOfSpeech,
              definition: vocab.definition,
              definitionVi: vi,
              example: vocab.example,
              audioUrl: vocab.audioUrl,
              imageUrl: vocab.imageUrl,
              level: vocab.level,
              topic: vocab.topic,
              isSaved: vocab.isSaved,
            );
          }
        }
      } else {
        // 2. Gọi Free Dictionary API
        final res = await http.get(
          Uri.parse('$_dictApi/$_searchQuery'),
        ).timeout(const Duration(seconds: 8));

        if (res.statusCode != 200) {
          _error = 'Không tìm thấy từ "$_searchQuery"';
          _isSearching = false;
          notifyListeners();
          return null;
        }

        final data = jsonDecode(res.body) as List;
        vocab = VocabularyModel.fromApi(data[0]);

        // 3. Dịch definition sang tiếng Việt song song
        final vi = await _translateToVi(vocab.definition);

        // 4. Tạo vocab mới có nghĩa Việt
        vocab = VocabularyModel(
          word: vocab.word,
          phonetic: vocab.phonetic,
          partOfSpeech: vocab.partOfSpeech,
          definition: vocab.definition,
          definitionVi: vi,
          example: vocab.example,
          audioUrl: vocab.audioUrl,
          level: vocab.level,
        );

        // 5. Cache vào SQLite (kể cả nghĩa Việt)
        try {
          await db.insert('vocabulary', vocab.toMap(),
              conflictAlgorithm: ConflictAlgorithm.ignore);
        } catch (_) {}

        // Lấy lại với id từ DB
        final inserted = await db.query(
          'vocabulary',
          where: 'LOWER(word) = ?',
          whereArgs: [_searchQuery],
          limit: 1,
        );
        if (inserted.isNotEmpty) vocab = VocabularyModel.fromMap(inserted.first);
      }

      // Kiểm tra đã saved chưa
      if (userId != null && vocab.id != null) {
        final saved = await db.query(
          'saved_words',
          where: 'user_id = ? AND vocab_id = ?',
          whereArgs: [userId, vocab.id],
        );
        vocab.isSaved = saved.isNotEmpty;
      }

      // Thêm vào kết quả & flashcard deck
      _searchResults.removeWhere((v) => v.word == vocab.word);
      _searchResults.insert(0, vocab);

      if (!_flashcardDeck.any((v) => v.word == vocab.word)) {
        _flashcardDeck.insert(0, vocab);
        _currentCardIndex = 0;
      }

      // Lưu lịch sử
      await _saveSearchHistory(word, userId);

      _isSearching = false;
      notifyListeners();
      return vocab;
    } catch (e) {
      _error = 'Lỗi kết nối: $e';
      _isSearching = false;
      notifyListeners();
      return null;
    }
  }

  // ── Flashcard navigation ──────────────────────────────────────────────────
  void nextCard() {
    if (_currentCardIndex < _flashcardDeck.length - 1) {
      _currentCardIndex++;
      notifyListeners();
    }
  }

  void prevCard() {
    if (_currentCardIndex > 0) {
      _currentCardIndex--;
      notifyListeners();
    }
  }

  void removeFromDeck(int index) {
    if (index >= 0 && index < _flashcardDeck.length) {
      _flashcardDeck.removeAt(index);
      if (_currentCardIndex >= _flashcardDeck.length && _currentCardIndex > 0) {
        _currentCardIndex--;
      }
      notifyListeners();
    }
  }

  void clearDeck() {
    _flashcardDeck.clear();
    _currentCardIndex = 0;
    notifyListeners();
  }

  // ── Lưu / Bỏ lưu từ ──────────────────────────────────────────────────────
  Future<void> toggleSaveWord(VocabularyModel vocab, int userId) async {
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query(
      'saved_words',
      where: 'user_id = ? AND vocab_id = ?',
      whereArgs: [userId, vocab.id],
    );
    if (existing.isNotEmpty) {
      await db.delete('saved_words',
          where: 'user_id = ? AND vocab_id = ?',
          whereArgs: [userId, vocab.id]);
      vocab.isSaved = false;
    } else {
      await db.insert('saved_words', {
        'user_id': userId,
        'vocab_id': vocab.id,
        'saved_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      vocab.isSaved = true;
    }
    notifyListeners();
    await loadSavedWords(userId);
  }

  // ── Load từ đã lưu ────────────────────────────────────────────────────────
  Future<void> loadSavedWords(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery('''
      SELECT v.*, sw.mastered, sw.review_count
      FROM vocabulary v
      JOIN saved_words sw ON v.id = sw.vocab_id
      WHERE sw.user_id = ?
      ORDER BY sw.saved_at DESC
    ''', [userId]);
    _savedWords = rows.map((r) => VocabularyModel.fromMap(r)).toList();
    notifyListeners();
  }

  // ── Autocomplete suggestions ──────────────────────────────────────────────
  Future<List<String>> getSuggestions(String query) async {
    if (query.length < 2) return [];
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'vocabulary',
      columns: ['word'],
      where: 'word LIKE ?',
      whereArgs: ['$query%'],
      limit: 8,
    );
    return rows.map((r) => r['word'] as String).toList();
  }

  // ── Lịch sử search ────────────────────────────────────────────────────────
  Future<void> _saveSearchHistory(String word, int? userId) async {
    _searchHistory.remove(word);
    _searchHistory.insert(0, word);
    if (_searchHistory.length > 20) _searchHistory.removeLast();

    if (userId != null) {
      final db = await DatabaseHelper.instance.database;
      await db.insert('search_history', {
        'user_id': userId,
        'word': word,
        'searched_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> loadSearchHistory(int userId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'search_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'searched_at DESC',
      limit: 20,
    );
    _searchHistory = rows.map((r) => r['word'] as String).toList();
    notifyListeners();
  }

  void clearSearch() {
    _searchResults.clear();
    _error = null;
    _searchQuery = '';
    notifyListeners();
  }
}