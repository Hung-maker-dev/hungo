// lib/core/services/grammar_checker.dart
// Thuật toán kiểm tra các thì tiếng Anh dựa trên pattern matching + signal words

class GrammarChecker {
  // ── Signal words cho từng thì ─────────────────────────────────────────────
  static const Map<String, List<String>> _signalWords = {
    'simple_present':    ['always', 'usually', 'often', 'sometimes', 'never', 'every day', 'every week', 'every month', 'every year', 'on mondays', 'generally', 'normally', 'regularly'],
    'present_continuous':['now', 'at the moment', 'at present', 'currently', 'right now', 'still', 'look!', 'listen!', 'this week', 'today'],
    'present_perfect':   ['already', 'yet', 'just', 'ever', 'never', 'for', 'since', 'so far', 'up to now', 'lately', 'recently', 'before', 'many times'],
    'present_perfect_cont':['for', 'since', 'all day', 'all morning', 'how long', 'the whole day'],
    'simple_past':       ['yesterday', 'last week', 'last month', 'last year', 'ago', 'in 2020', 'in 2019', 'then', 'when i was', 'in the past', 'earlier today'],
    'past_continuous':   ['while', 'when', 'as', 'at this time yesterday', 'at 8pm yesterday', 'all day yesterday'],
    'past_perfect':      ['before', 'after', 'by the time', 'already', 'by then', 'when he arrived', 'when she came', 'until then'],
    'past_perfect_cont': ['for', 'since', 'before', 'until', 'how long ... had'],
    'simple_future':     ['tomorrow', 'next week', 'next month', 'next year', 'soon', 'in the future', 'someday', 'one day', 'tonight', 'later'],
    'future_continuous': ['at this time tomorrow', 'at 8pm tomorrow', 'this time next week'],
    'future_perfect':    ['by then', 'by 2026', 'by tomorrow', 'by next week', 'by the time', 'before then'],
    'future_perfect_cont':['for', 'by the time', 'until', 'how long ... will have been'],
  };

  // ── Verb form patterns (regex) ────────────────────────────────────────────
  static final Map<String, RegExp> _patterns = {
    'simple_present':
        RegExp(r'\b(I|you|we|they)\s+([\w]+)\b|\b(he|she|it)\s+([\w]+s|[\w]+es)\b', caseSensitive: false),
    'present_continuous':
        RegExp(r'\b(am|is|are)\s+(\w+ing)\b', caseSensitive: false),
    'present_perfect':
        RegExp(r'\b(have|has)\s+([\w]+ed|[\w]+en|been|gone|done|seen|made|taken|had|come|run|won|met|sat|set|put|let|cut|hit|hurt|shut|cost|beat|burst|cast|rid|set)\b', caseSensitive: false),
    'present_perfect_cont':
        RegExp(r'\b(have|has)\s+been\s+(\w+ing)\b', caseSensitive: false),
    'simple_past':
        RegExp(r'\b(I|you|he|she|it|we|they)\s+(was|were|[\w]+ed|went|came|saw|did|had|made|took|told|gave|found|knew|thought|said|got|kept|left|lost|put|read|ran|stood|understood|won|wrote)\b', caseSensitive: false),
    'past_continuous':
        RegExp(r'\b(was|were)\s+(\w+ing)\b', caseSensitive: false),
    'past_perfect':
        RegExp(r'\bhad\s+([\w]+ed|[\w]+en|been|gone|done|seen|made|taken|had|come|run|won|met|sat|set|put|let|cut|hit|hurt|shut|cost|beat|burst)\b', caseSensitive: false),
    'past_perfect_cont':
        RegExp(r'\bhad\s+been\s+(\w+ing)\b', caseSensitive: false),
    'simple_future':
        RegExp(r'\bwill\s+(?!have\b)(?!be\s+\w+ing\b)(\w+)\b|\bam\s+going\s+to\s+(\w+)\b|\bwas\s+going\s+to\s+(\w+)\b', caseSensitive: false),
    'future_continuous':
        RegExp(r'\bwill\s+be\s+(\w+ing)\b', caseSensitive: false),
    'future_perfect':
        RegExp(r'\bwill\s+have\s+(?!been\s+\w+ing)([\w]+)\b', caseSensitive: false),
    'future_perfect_cont':
        RegExp(r'\bwill\s+have\s+been\s+(\w+ing)\b', caseSensitive: false),
  };

  // ── Tên hiển thị ──────────────────────────────────────────────────────────
  static const Map<String, String> _tenseNames = {
    'simple_present':     'Simple Present (Hiện tại đơn)',
    'present_continuous': 'Present Continuous (Hiện tại tiếp diễn)',
    'present_perfect':    'Present Perfect (Hiện tại hoàn thành)',
    'present_perfect_cont':'Present Perfect Continuous',
    'simple_past':        'Simple Past (Quá khứ đơn)',
    'past_continuous':    'Past Continuous (Quá khứ tiếp diễn)',
    'past_perfect':       'Past Perfect (Quá khứ hoàn thành)',
    'past_perfect_cont':  'Past Perfect Continuous',
    'simple_future':      'Simple Future (Tương lai đơn)',
    'future_continuous':  'Future Continuous (Tương lai tiếp diễn)',
    'future_perfect':     'Future Perfect (Tương lai hoàn thành)',
    'future_perfect_cont':'Future Perfect Continuous',
  };

  // ── Kiểm tra thì của câu ─────────────────────────────────────────────────
  /// Trả về kết quả: thì được phát hiện, điểm tin cậy, tên đầy đủ
  static GrammarCheckResult detectTense(String sentence) {
    final s = sentence.trim().toLowerCase();
    Map<String, int> scores = {};

    // 1. Ưu tiên perfect continuous (phức tạp nhất, check trước)
    for (final tense in [
      'future_perfect_cont', 'past_perfect_cont', 'present_perfect_cont',
      'future_perfect', 'past_perfect', 'present_perfect',
      'future_continuous', 'past_continuous', 'present_continuous',
      'simple_future', 'simple_past', 'simple_present',
    ]) {
      final pattern = _patterns[tense];
      if (pattern != null && pattern.hasMatch(s)) {
        scores[tense] = (scores[tense] ?? 0) + 3; // pattern match = 3 điểm
      }
    }

    // 2. Signal words bonus
    for (final entry in _signalWords.entries) {
      for (final signal in entry.value) {
        if (s.contains(signal.toLowerCase())) {
          scores[entry.key] = (scores[entry.key] ?? 0) + 2; // signal = 2 điểm
        }
      }
    }

    if (scores.isEmpty) {
      return GrammarCheckResult(
        detectedTense: 'unknown',
        tenseName: 'Không xác định được thì',
        confidence: 0,
        suggestions: ['Câu có thể chưa đầy đủ hoặc không rõ ràng.'],
      );
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final best = sorted.first;
    final confidence = ((best.value / (best.value + 2)) * 100).round();

    return GrammarCheckResult(
      detectedTense: best.key,
      tenseName: _tenseNames[best.key] ?? best.key,
      confidence: confidence,
      alternativeTenses: sorted.skip(1).take(2)
          .map((e) => _tenseNames[e.key] ?? e.key).toList(),
      suggestions: _getSuggestions(best.key, s),
    );
  }

  // ── Kiểm tra đáp án bài tập ───────────────────────────────────────────────
  /// So sánh câu trả lời của user với đáp án đúng
  /// Linh hoạt: chấp nhận các biến thể (contractions, spacing)
  static bool checkAnswer(String userAnswer, String correctAnswer) {
    final clean = (String s) => s.trim().toLowerCase()
        .replaceAll("'s", ' is').replaceAll("'re", ' are')
        .replaceAll("'ve", ' have').replaceAll("'ll", ' will')
        .replaceAll("'t", ' not').replaceAll(RegExp(r'\s+'), ' ');

    final u = clean(userAnswer);
    final c = clean(correctAnswer);
    if (u == c) return true;

    // Kiểm tra verb form tương đương
    // VD: "have gone" == "have gone" (đơn giản)
    return u == c;
  }

  // ── Kiểm tra câu điền vào chỗ trống ──────────────────────────────────────
  /// template: "She ___ (go) to school every day."
  /// answer: "goes"
  static FillBlankResult checkFillBlank({
    required String template,
    required String userAnswer,
    required String correctAnswer,
    String? baseVerb,
  }) {
    final isCorrect = checkAnswer(userAnswer, correctAnswer);
    final verbAnalysis = baseVerb != null
        ? _analyzeVerbForm(userAnswer.trim().toLowerCase(), baseVerb.toLowerCase())
        : null;

    return FillBlankResult(
      isCorrect: isCorrect,
      userAnswer: userAnswer,
      correctAnswer: correctAnswer,
      verbForm: verbAnalysis,
      explanation: isCorrect ? null : _getVerbExplanation(correctAnswer),
    );
  }

  // ── Phân tích dạng động từ ────────────────────────────────────────────────
  static String _analyzeVerbForm(String verbUsed, String baseVerb) {
    if (verbUsed == '${baseVerb}s' || verbUsed == '${baseVerb}es' ||
        verbUsed == '${baseVerb.replaceAll('y', 'ies')}') return 'V(s/es) — 3rd person singular';
    if (verbUsed == '${baseVerb}ing') return 'V-ing — present participle';
    if (verbUsed == '${baseVerb}ed') return 'V2/V3 — past/past participle';
    if (verbUsed == baseVerb) return 'Base form — V1';
    return 'Irregular form';
  }

  static String _getVerbExplanation(String correctForm) {
    if (RegExp(r'(am|is|are)\s+\w+ing').hasMatch(correctForm))
      return 'Dùng thì Hiện tại tiếp diễn: am/is/are + V-ing';
    if (RegExp(r'(have|has)\s+been\s+\w+ing').hasMatch(correctForm))
      return 'Dùng thì Hiện tại hoàn thành tiếp diễn: have/has been + V-ing';
    if (RegExp(r'(have|has)\s+\w+').hasMatch(correctForm))
      return 'Dùng thì Hiện tại hoàn thành: have/has + V3';
    if (RegExp(r'(was|were)\s+\w+ing').hasMatch(correctForm))
      return 'Dùng thì Quá khứ tiếp diễn: was/were + V-ing';
    if (RegExp(r'will\s+be\s+\w+ing').hasMatch(correctForm))
      return 'Dùng thì Tương lai tiếp diễn: will be + V-ing';
    if (RegExp(r'will\s+have').hasMatch(correctForm))
      return 'Dùng thì Tương lai hoàn thành: will have + V3';
    if (RegExp(r'had\s+been').hasMatch(correctForm))
      return 'Dùng thì Quá khứ hoàn thành tiếp diễn: had been + V-ing';
    if (RegExp(r'\bhad\b').hasMatch(correctForm))
      return 'Dùng thì Quá khứ hoàn thành: had + V3';
    if (RegExp(r'\bwill\b').hasMatch(correctForm))
      return 'Dùng thì Tương lai đơn: will + V';
    return 'Kiểm tra lại dạng động từ của bạn.';
  }

  static List<String> _getSuggestions(String tense, String sentence) {
    final signals = _signalWords[tense] ?? [];
    final found = signals.where((s) => sentence.contains(s)).take(2).toList();
    final tips = <String>[];
    if (found.isNotEmpty) tips.add('Từ tín hiệu nhận biết: ${found.join(', ')}');
    tips.add('Công thức: ${_getFormula(tense)}');
    return tips;
  }

  static String _getFormula(String tense) {
    const formulas = {
      'simple_present':     'S + V(s/es)',
      'present_continuous': 'S + am/is/are + V-ing',
      'present_perfect':    'S + have/has + V3',
      'present_perfect_cont':'S + have/has + been + V-ing',
      'simple_past':        'S + V2/ed',
      'past_continuous':    'S + was/were + V-ing',
      'past_perfect':       'S + had + V3',
      'past_perfect_cont':  'S + had + been + V-ing',
      'simple_future':      'S + will + V',
      'future_continuous':  'S + will + be + V-ing',
      'future_perfect':     'S + will + have + V3',
      'future_perfect_cont':'S + will + have + been + V-ing',
    };
    return formulas[tense] ?? 'Không rõ';
  }
}

// ── Result classes ────────────────────────────────────────────────────────────

class GrammarCheckResult {
  final String detectedTense;
  final String tenseName;
  final int confidence; // 0-100
  final List<String> alternativeTenses;
  final List<String> suggestions;

  GrammarCheckResult({
    required this.detectedTense,
    required this.tenseName,
    required this.confidence,
    this.alternativeTenses = const [],
    this.suggestions = const [],
  });
}

class FillBlankResult {
  final bool isCorrect;
  final String userAnswer;
  final String correctAnswer;
  final String? verbForm;
  final String? explanation;

  FillBlankResult({
    required this.isCorrect,
    required this.userAnswer,
    required this.correctAnswer,
    this.verbForm,
    this.explanation,
  });
}
