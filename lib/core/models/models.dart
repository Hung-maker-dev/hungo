// lib/core/models/user_model.dart
class UserModel {
  final int? id;
  final String username;
  final String email;
  final String password;
  final String role; // 'user' | 'admin'
  final String? avatarUrl;
  final String createdAt;
  final String? lastLogin;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    this.role = 'user',
    this.avatarUrl,
    required this.createdAt,
    this.lastLogin,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
    id: m['id'], username: m['username'], email: m['email'],
    password: m['password'], role: m['role'] ?? 'user',
    avatarUrl: m['avatar_url'], createdAt: m['created_at'] ?? '',
    lastLogin: m['last_login'],
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'username': username, 'email': email, 'password': password,
    'role': role, 'avatar_url': avatarUrl, 'created_at': createdAt,
    'last_login': lastLogin,
  };
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/core/models/vocabulary_model.dart
class VocabularyModel {
  final int? id;
  final String word;
  final String? phonetic;
  final String? partOfSpeech;
  final String definition;
  final String? definitionVi;
  final String? example;
  final String? audioUrl;
  final String? imageUrl;
  final String level;
  final String? topic;
  bool isSaved;

  VocabularyModel({
    this.id, required this.word, this.phonetic, this.partOfSpeech,
    required this.definition, this.definitionVi, this.example,
    this.audioUrl, this.imageUrl, this.level = 'A1', this.topic,
    this.isSaved = false,
  });

  factory VocabularyModel.fromMap(Map<String, dynamic> m) => VocabularyModel(
    id: m['id'], word: m['word'], phonetic: m['phonetic'],
    partOfSpeech: m['part_of_speech'], definition: m['definition'],
    definitionVi: m['definition_vi'], example: m['example'],
    audioUrl: m['audio_url'], imageUrl: m['image_url'],
    level: m['level'] ?? 'A1', topic: m['topic'],
  );

  // Parse từ Free Dictionary API
  factory VocabularyModel.fromApi(Map<String, dynamic> json) {
    final meanings = json['meanings'] as List? ?? [];
    final firstMeaning = meanings.isNotEmpty ? meanings[0] : null;
    final defs = firstMeaning != null ? (firstMeaning['definitions'] as List? ?? []) : [];
    final phonetics = json['phonetics'] as List? ?? [];
    String? audio;
    for (final p in phonetics) {
      if (p['audio'] != null && (p['audio'] as String).isNotEmpty) {
        audio = p['audio']; break;
      }
    }
    return VocabularyModel(
      word: json['word'] ?? '',
      phonetic: json['phonetic'] ?? (phonetics.isNotEmpty ? phonetics[0]['text'] : null),
      partOfSpeech: firstMeaning?['partOfSpeech'],
      definition: defs.isNotEmpty ? (defs[0]['definition'] ?? '') : 'No definition found',
      example: defs.isNotEmpty ? defs[0]['example'] : null,
      audioUrl: audio,
    );
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'word': word, 'phonetic': phonetic, 'part_of_speech': partOfSpeech,
    'definition': definition, 'definition_vi': definitionVi,
    'example': example, 'audio_url': audioUrl, 'image_url': imageUrl,
    'level': level, 'topic': topic,
  };
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/core/models/grammar_model.dart
class GrammarTopic {
  final int? id;
  final String name;
  final String? nameVi;
  final String category; // present | past | future
  final String theory;
  final String? formula;
  final String? signalWords;
  final String? examplePos;
  final String? exampleNeg;
  final String? exampleQue;
  final int orderIndex;

  GrammarTopic({
    this.id, required this.name, this.nameVi, required this.category,
    required this.theory, this.formula, this.signalWords,
    this.examplePos, this.exampleNeg, this.exampleQue, this.orderIndex = 0,
  });

  factory GrammarTopic.fromMap(Map<String, dynamic> m) => GrammarTopic(
    id: m['id'], name: m['name'], nameVi: m['name_vi'],
    category: m['category'], theory: m['theory'],
    formula: m['formula'], signalWords: m['signal_words'],
    examplePos: m['example_pos'], exampleNeg: m['example_neg'],
    exampleQue: m['example_que'], orderIndex: m['order_index'] ?? 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/core/models/lesson_model.dart
class LessonModel {
  final int? id;
  final String title;
  final String skill; // reading | listening | grammar | writing
  final String level;
  final String? content;
  final String? audioUrl;
  final String? thumbnail;
  final String? description;
  final bool isPublished;
  final String? createdAt;

  LessonModel({
    this.id, required this.title, required this.skill,
    this.level = 'A1', this.content, this.audioUrl, this.thumbnail,
    this.description, this.isPublished = true, this.createdAt,
  });

  factory LessonModel.fromMap(Map<String, dynamic> m) => LessonModel(
    id: m['id'], title: m['title'], skill: m['skill'],
    level: m['level'] ?? 'A1', content: m['content'],
    audioUrl: m['audio_url'], thumbnail: m['thumbnail'],
    description: m['description'],
    isPublished: (m['is_published'] ?? 1) == 1,
    createdAt: m['created_at'],
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'title': title, 'skill': skill, 'level': level,
    'content': content, 'audio_url': audioUrl, 'thumbnail': thumbnail,
    'description': description, 'is_published': isPublished ? 1 : 0,
  };
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/core/models/question_model.dart
class QuestionModel {
  final int? id;
  final int lessonId;
  final String questionText;
  final String questionType; // mcq | fill_blank | true_false | grammar_check
  final List<String>? options; // MCQ options
  final String correctAnswer;
  final String? explanation;
  final int points;
  final int orderIndex;

  QuestionModel({
    this.id, required this.lessonId, required this.questionText,
    required this.questionType, this.options, required this.correctAnswer,
    this.explanation, this.points = 10, this.orderIndex = 0,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> m) {
    List<String>? opts;
    if (m['options'] != null) {
      // Parse JSON string
      try {
        final raw = m['options'] as String;
        opts = raw.replaceAll('[', '').replaceAll(']', '')
            .replaceAll('"', '').split(',').map((e) => e.trim()).toList();
      } catch (_) {}
    }
    return QuestionModel(
      id: m['id'], lessonId: m['lesson_id'],
      questionText: m['question_text'], questionType: m['question_type'],
      options: opts, correctAnswer: m['correct_ans'],
      explanation: m['explanation'], points: m['points'] ?? 10,
      orderIndex: m['order_index'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'lesson_id': lessonId, 'question_text': questionText,
    'question_type': questionType,
    'options': options != null ? '[${options!.map((e) => '"$e"').join(',')}]' : null,
    'correct_ans': correctAnswer, 'explanation': explanation,
    'points': points, 'order_index': orderIndex,
  };
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/core/models/progress_model.dart
class UserProgress {
  final int? id;
  final int userId;
  final int? lessonId;
  final int? grammarId;
  final String skill;
  final int score;
  final int maxScore;
  final bool isCompleted;
  final int timeSpent;
  final int attempts;
  final String? completedAt;

  UserProgress({
    this.id, required this.userId, this.lessonId, this.grammarId,
    required this.skill, this.score = 0, this.maxScore = 100,
    this.isCompleted = false, this.timeSpent = 0, this.attempts = 1,
    this.completedAt,
  });

  double get percentage => maxScore > 0 ? score / maxScore : 0;
  String get grade {
    final p = percentage;
    if (p >= 0.9) return 'A+';
    if (p >= 0.8) return 'A';
    if (p >= 0.7) return 'B';
    if (p >= 0.6) return 'C';
    return 'F';
  }

  factory UserProgress.fromMap(Map<String, dynamic> m) => UserProgress(
    id: m['id'], userId: m['user_id'], lessonId: m['lesson_id'],
    grammarId: m['grammar_id'], skill: m['skill'],
    score: m['score'] ?? 0, maxScore: m['max_score'] ?? 100,
    isCompleted: (m['is_completed'] ?? 0) == 1,
    timeSpent: m['time_spent'] ?? 0, attempts: m['attempts'] ?? 1,
    completedAt: m['completed_at'],
  );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId, 'lesson_id': lessonId, 'grammar_id': grammarId,
    'skill': skill, 'score': score, 'max_score': maxScore,
    'is_completed': isCompleted ? 1 : 0, 'time_spent': timeSpent,
    'attempts': attempts, 'completed_at': completedAt,
  };
}
