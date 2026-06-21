// lib/core/database/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'english_app.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onOpen: (db) async {
        await db.rawQuery('PRAGMA journal_mode = WAL');
      },
    );
  }
  Future<void> _addColumnIfNotExists(
      Database db,
      String table,
      String column,
      String type,
      ) async {
    final columns = await db.rawQuery(
      'PRAGMA table_info($table)',
    );

    final exists = columns.any(
          (c) => c['name'] == column,
    );

    if (!exists) {
      await db.execute(
        'ALTER TABLE $table ADD COLUMN $column $type',
      );
    }
  }
  Future<void> _onUpgrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {

    // Version 3
    if (oldVersion < 3) {
      await _addColumnIfNotExists(
        db,
        'lessons',
        'topic',
        'TEXT',
      );
    }

    // Version 4
    if (oldVersion < 4) {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS writing_submissions (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        lesson_id    INTEGER NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
        question_id  INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
        user_id      INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        answer_text  TEXT NOT NULL,
        status       TEXT NOT NULL DEFAULT 'pending',
        score        INTEGER,
        max_score    INTEGER,
        feedback     TEXT,
        submitted_at TEXT NOT NULL DEFAULT (datetime('now')),
        graded_at    TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_sub_user ON writing_submissions(user_id)');
    await db.execute(
      'CREATE INDEX idx_sub_lesson ON writing_submissions(lesson_id)');
    await db.execute(
      'CREATE INDEX idx_sub_status ON writing_submissions(status)');
  }

    // Version 5
    if (oldVersion < 5) {
      await _addColumnIfNotExists(
        db,
        'lessons',
        'difficulty',
        'TEXT',
      );
    }
  }

  // ── WRITING SUBMISSIONS ─────────────────────────────────────────────────

  /// Học viên nộp bài — tạo row mới mỗi lần nộp (cho phép nộp lại)
  Future<int> insertSubmission(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('writing_submissions', data);
  }

  /// Lấy tất cả bài nộp của 1 user cho 1 question (để hiện lịch sử)
  Future<List<Map<String, dynamic>>> getSubmissionsByUserAndQuestion({
    required int userId,
    required int questionId,
  }) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.*,
             l.title  AS lesson_title,
             q.question_text
      FROM   writing_submissions s
      JOIN   lessons   l ON l.id = s.lesson_id
      JOIN   questions q ON q.id = s.question_id
      WHERE  s.user_id    = ?
        AND  s.question_id = ?
      ORDER  BY s.submitted_at DESC
    ''', [userId, questionId]);
  }

  /// Lấy tất cả bài nộp của 1 user (cho trang "bài viết của tôi")
  Future<List<Map<String, dynamic>>> getSubmissionsByUser(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.*,
             l.title          AS lesson_title,
             q.question_text
      FROM   writing_submissions s
      JOIN   lessons   l ON l.id = s.lesson_id
      JOIN   questions q ON q.id = s.question_id
      WHERE  s.user_id = ?
      ORDER  BY s.submitted_at DESC
    ''', [userId]);
  }

  /// Admin: lấy danh sách bài chờ chấm (status = 'pending')
  Future<List<Map<String, dynamic>>> getPendingSubmissions() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT s.*,
             u.username,
             l.title          AS lesson_title,
             q.question_text,
             q.correct_ans    AS sample_answer,
             q.points         AS max_score
      FROM   writing_submissions s
      JOIN   users     u ON u.id = s.user_id
      JOIN   lessons   l ON l.id = s.lesson_id
      JOIN   questions q ON q.id = s.question_id
      WHERE  s.status = 'pending'
      ORDER  BY s.submitted_at ASC
    ''');
  }

  /// Admin: lấy tất cả bài (pending + graded) để xem lịch sử
  Future<List<Map<String, dynamic>>> getAllSubmissions({String? status}) async {
    final db = await database;
    final where = status != null ? "WHERE s.status = '$status'" : '';
    return await db.rawQuery('''
      SELECT s.*,
             u.username,
             l.title          AS lesson_title,
             q.question_text,
             q.correct_ans    AS sample_answer,
             q.points         AS max_score
      FROM   writing_submissions s
      JOIN   users     u ON u.id = s.user_id
      JOIN   lessons   l ON l.id = s.lesson_id
      JOIN   questions q ON q.id = s.question_id
      $where
      ORDER  BY s.submitted_at DESC
    ''');
  }

  /// Admin chấm bài: cập nhật score + feedback + status
  Future<void> gradeSubmission({
    required int submissionId,
    required int score,
    required int maxScore,
    String? feedback,
  }) async {
    final db = await database;
    await db.update(
      'writing_submissions',
      {
        'score':     score,
        'max_score': maxScore,
        'feedback':  feedback,
        'status':    'graded',
        'graded_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [submissionId],
    );
  }

  /// Đếm số bài chờ chấm (dùng cho badge trên admin dashboard)
  Future<int> countPendingSubmissions() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as c FROM writing_submissions WHERE status = 'pending'",
    );
    return result.first['c'] as int;
  }

  Future<void> _onCreate(Database db, int version) async {
    // ── BẢNG NGƯỜI DÙNG ──────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE users (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        username    TEXT NOT NULL UNIQUE,
        email       TEXT NOT NULL UNIQUE,
        password    TEXT NOT NULL,         -- hash bcrypt / sha256
        role        TEXT NOT NULL DEFAULT 'user',  -- 'user' | 'admin'
        avatar_url  TEXT,
        created_at  TEXT NOT NULL DEFAULT (datetime('now')),
        last_login  TEXT
      )
    ''');

    // ── BẢNG TỪ VỰNG (admin thêm) ────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE vocabulary (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        word          TEXT NOT NULL UNIQUE,
        phonetic      TEXT,
        part_of_speech TEXT,              -- noun, verb, adj...
        definition    TEXT NOT NULL,
        definition_vi TEXT,               -- nghĩa tiếng Việt
        example       TEXT,
        audio_url     TEXT,
        image_url     TEXT,
        level         TEXT DEFAULT 'A1', -- A1 A2 B1 B2 C1 C2
        topic         TEXT,               -- travel, food, business...
        created_by    INTEGER REFERENCES users(id),
        created_at    TEXT DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('CREATE INDEX idx_vocab_word ON vocabulary(word)');
    await db.execute('CREATE INDEX idx_vocab_level ON vocabulary(level)');
    await db.execute('CREATE INDEX idx_vocab_topic ON vocabulary(topic)');

    // ── TỪ ĐÃ LƯU CỦA USER ───────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE saved_words (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        vocab_id    INTEGER NOT NULL REFERENCES vocabulary(id) ON DELETE CASCADE,
        saved_at    TEXT DEFAULT (datetime('now')),
        review_count INTEGER DEFAULT 0,
        next_review  TEXT,                -- Spaced Repetition
        mastered     INTEGER DEFAULT 0,   -- 0 | 1
        UNIQUE(user_id, vocab_id)
      )
    ''');
    await db.execute('CREATE INDEX idx_saved_user ON saved_words(user_id)');

    // ── LỊCH SỬ SEARCH ───────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE search_history (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id   INTEGER REFERENCES users(id) ON DELETE CASCADE,
        word      TEXT NOT NULL,
        searched_at TEXT DEFAULT (datetime('now'))
      )
    ''');

    // ── BÀI HỌC / LESSON (admin tạo) ─────────────────────────────────────────
    await db.execute('''
      CREATE TABLE lessons (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        title        TEXT NOT NULL,
        skill        TEXT NOT NULL,  -- 'reading' | 'listening' | 'grammar' | 'writing'
        level        TEXT DEFAULT 'A1',
        content      TEXT,           -- nội dung bài đọc / script nghe
        audio_url    TEXT,           -- cho bài listening
        thumbnail    TEXT,
        description  TEXT,
        topic        TEXT,
        is_published INTEGER DEFAULT 1,
        created_by   INTEGER REFERENCES users(id),
        created_at   TEXT DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('CREATE INDEX idx_lesson_skill ON lessons(skill)');
    await db.execute('CREATE INDEX idx_lesson_level ON lessons(level)');

    // ── CÂU HỎI BÀI TẬP ─────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE questions (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        lesson_id    INTEGER NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
        question_text TEXT NOT NULL,
        question_type TEXT NOT NULL, -- 'mcq' | 'fill_blank' | 'true_false' | 'grammar_check'
        options      TEXT,           -- JSON array ["A","B","C","D"]
        correct_ans  TEXT NOT NULL,
        explanation  TEXT,
        points       INTEGER DEFAULT 10,
        order_index  INTEGER DEFAULT 0
      )
    ''');

    // ── NGỮ PHÁP / CÁC THÌ ───────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE grammar_topics (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT NOT NULL,        -- "Simple Present", "Past Continuous"...
        name_vi     TEXT,                 -- "Hiện tại đơn"
        category    TEXT NOT NULL,        -- "present" | "past" | "future" | "perfect"
        theory      TEXT NOT NULL,        -- nội dung lý thuyết (Markdown)
        formula     TEXT,                 -- S + V(s/es) / S + was/were + V-ing
        signal_words TEXT,                -- always, often, now, ...
        example_pos  TEXT,                -- câu khẳng định
        example_neg  TEXT,                -- câu phủ định
        example_que  TEXT,                -- câu hỏi
        order_index  INTEGER DEFAULT 0
      )
    ''');

    // ── BÀI TẬP NGỮ PHÁP ────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE grammar_exercises (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        grammar_id      INTEGER NOT NULL REFERENCES grammar_topics(id) ON DELETE CASCADE,
        exercise_text   TEXT NOT NULL,    -- "She ___ (go) to school every day"
        exercise_type   TEXT NOT NULL,    -- 'fill_blank' | 'mcq' | 'error_correction' | 'sentence_rewrite'
        correct_answer  TEXT NOT NULL,    -- "goes"
        options         TEXT,             -- JSON nếu MCQ
        hint            TEXT,
        explanation     TEXT,
        difficulty      INTEGER DEFAULT 1 -- 1=easy 2=medium 3=hard
      )
    ''');

    // ── TIẾN ĐỘ NGƯỜI DÙNG ───────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE user_progress (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id      INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        lesson_id    INTEGER REFERENCES lessons(id) ON DELETE CASCADE,
        grammar_id   INTEGER REFERENCES grammar_topics(id) ON DELETE CASCADE,
        skill        TEXT NOT NULL,
        score        INTEGER DEFAULT 0,
        max_score    INTEGER DEFAULT 100,
        is_completed INTEGER DEFAULT 0,
        time_spent   INTEGER DEFAULT 0,  -- giây
        attempts     INTEGER DEFAULT 1,
        completed_at TEXT,
        created_at   TEXT DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('CREATE INDEX idx_progress_user ON user_progress(user_id)');
    await db.execute('CREATE INDEX idx_progress_skill ON user_progress(skill)');

    // ── ĐIỂM SỐ / LEADERBOARD ────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE scores (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id   INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        skill     TEXT NOT NULL,
        total_pts INTEGER DEFAULT 0,
        streak    INTEGER DEFAULT 0,   -- chuỗi ngày học liên tiếp
        last_study TEXT,
        updated_at TEXT DEFAULT (datetime('now')),
        UNIQUE(user_id, skill)
      )
    ''');

    // ── THÔNG BÁO ────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE notifications (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id     INTEGER REFERENCES users(id) ON DELETE CASCADE,
        title       TEXT NOT NULL,
        body        TEXT NOT NULL,
        type        TEXT DEFAULT 'info',  -- 'info' | 'reminder' | 'achievement'
        is_read     INTEGER DEFAULT 0,
        created_at  TEXT DEFAULT (datetime('now'))
      )
    ''');

    await db.execute('''
      CREATE TABLE writing_submissions (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        lesson_id    INTEGER NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
        question_id  INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
        user_id      INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        answer_text  TEXT NOT NULL,
        status       TEXT NOT NULL DEFAULT 'pending',
        score        INTEGER,
        max_score    INTEGER,
        feedback     TEXT,
        submitted_at TEXT NOT NULL DEFAULT (datetime('now')),
        graded_at    TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_sub_user ON writing_submissions(user_id)');
    await db.execute(
      'CREATE INDEX idx_sub_lesson ON writing_submissions(lesson_id)');
    await db.execute(
      'CREATE INDEX idx_sub_status ON writing_submissions(status)');

    // ── SEED DATA: admin + grammar topics ────────────────────────────────────
    await _seedData(db);
  }

  Future<void> _seedData(Database db) async {
    // Tài khoản admin mặc định (password: admin123 - đã hash)
    await db.insert('users', {
      'username': 'admin',
      'email': 'admin@englishapp.com',
      'password': sha256.convert(utf8.encode('admin123')).toString(), // ✅ FIX
      'role': 'admin',
    });

    // Seed 12 thì tiếng Anh
    final List<Map<String, dynamic>> tenses = [
      {'name': 'Simple Present', 'name_vi': 'Hiện tại đơn', 'category': 'present', 'formula': 'S + V(s/es)', 'signal_words': 'always, usually, often, sometimes, never, every day', 'example_pos': 'She goes to school every day.', 'example_neg': 'She does not go to school every day.', 'example_que': 'Does she go to school every day?', 'theory': '## Hiện tại đơn\nDùng diễn tả thói quen, sự thật hiển nhiên, lịch trình.', 'order_index': 1},
      {'name': 'Present Continuous', 'name_vi': 'Hiện tại tiếp diễn', 'category': 'present', 'formula': 'S + am/is/are + V-ing', 'signal_words': 'now, at the moment, currently, look!, listen!', 'example_pos': 'She is reading a book now.', 'example_neg': 'She is not reading a book now.', 'example_que': 'Is she reading a book now?', 'theory': '## Hiện tại tiếp diễn\nDùng diễn tả hành động đang xảy ra tại thời điểm nói.', 'order_index': 2},
      {'name': 'Present Perfect', 'name_vi': 'Hiện tại hoàn thành', 'category': 'present', 'formula': 'S + have/has + V3/ed', 'signal_words': 'already, yet, just, ever, never, for, since', 'example_pos': 'She has finished her homework.', 'example_neg': 'She has not finished her homework.', 'example_que': 'Has she finished her homework?', 'theory': '## Hiện tại hoàn thành\nDùng diễn tả hành động xảy ra trong quá khứ, kết quả ảnh hưởng đến hiện tại.', 'order_index': 3},
      {'name': 'Present Perfect Continuous', 'name_vi': 'Hiện tại hoàn thành tiếp diễn', 'category': 'present', 'formula': 'S + have/has + been + V-ing', 'signal_words': 'for, since, all day, how long', 'example_pos': 'She has been studying for 3 hours.', 'example_neg': 'She has not been studying for 3 hours.', 'example_que': 'Has she been studying for 3 hours?', 'theory': '## Hiện tại hoàn thành tiếp diễn\nNhấn mạnh tính liên tục của hành động từ quá khứ đến hiện tại.', 'order_index': 4},
      {'name': 'Simple Past', 'name_vi': 'Quá khứ đơn', 'category': 'past', 'formula': 'S + V2/ed', 'signal_words': 'yesterday, last week, ago, in 2020', 'example_pos': 'She went to school yesterday.', 'example_neg': 'She did not go to school yesterday.', 'example_que': 'Did she go to school yesterday?', 'theory': '## Quá khứ đơn\nDùng diễn tả hành động đã xảy ra và kết thúc trong quá khứ.', 'order_index': 5},
      {'name': 'Past Continuous', 'name_vi': 'Quá khứ tiếp diễn', 'category': 'past', 'formula': 'S + was/were + V-ing', 'signal_words': 'at 8pm yesterday, when, while', 'example_pos': 'She was studying when he called.', 'example_neg': 'She was not studying when he called.', 'example_que': 'Was she studying when he called?', 'theory': '## Quá khứ tiếp diễn\nDùng diễn tả hành động đang xảy ra tại một thời điểm trong quá khứ.', 'order_index': 6},
      {'name': 'Past Perfect', 'name_vi': 'Quá khứ hoàn thành', 'category': 'past', 'formula': 'S + had + V3/ed', 'signal_words': 'before, after, by the time, already', 'example_pos': 'She had left before he arrived.', 'example_neg': 'She had not left before he arrived.', 'example_que': 'Had she left before he arrived?', 'theory': '## Quá khứ hoàn thành\nDùng diễn tả hành động xảy ra TRƯỚC một hành động khác trong quá khứ.', 'order_index': 7},
      {'name': 'Past Perfect Continuous', 'name_vi': 'Quá khứ hoàn thành tiếp diễn', 'category': 'past', 'formula': 'S + had been + V-ing', 'signal_words': 'for, since, before, until', 'example_pos': 'She had been waiting for 2 hours when he arrived.', 'example_neg': 'She had not been waiting long.', 'example_que': 'Had she been waiting long?', 'theory': '## Quá khứ hoàn thành tiếp diễn\nNhấn mạnh tính liên tục của hành động trước một mốc quá khứ khác.', 'order_index': 8},
      {'name': 'Simple Future', 'name_vi': 'Tương lai đơn', 'category': 'future', 'formula': 'S + will + V', 'signal_words': 'tomorrow, next week, in the future, soon', 'example_pos': 'She will go to school tomorrow.', 'example_neg': 'She will not go to school tomorrow.', 'example_que': 'Will she go to school tomorrow?', 'theory': '## Tương lai đơn\nDùng diễn tả quyết định tức thì, dự đoán, lời hứa.', 'order_index': 9},
      {'name': 'Future Continuous', 'name_vi': 'Tương lai tiếp diễn', 'category': 'future', 'formula': 'S + will be + V-ing', 'signal_words': 'at this time tomorrow, at 8pm tomorrow', 'example_pos': 'She will be studying at 8pm tomorrow.', 'example_neg': 'She will not be studying at 8pm tomorrow.', 'example_que': 'Will she be studying at 8pm tomorrow?', 'theory': '## Tương lai tiếp diễn\nDùng diễn tả hành động đang xảy ra tại một thời điểm trong tương lai.', 'order_index': 10},
      {'name': 'Future Perfect', 'name_vi': 'Tương lai hoàn thành', 'category': 'future', 'formula': 'S + will have + V3/ed', 'signal_words': 'by then, by the time, by 2025', 'example_pos': 'She will have graduated by 2026.', 'example_neg': 'She will not have graduated by 2026.', 'example_que': 'Will she have graduated by 2026?', 'theory': '## Tương lai hoàn thành\nDùng diễn tả hành động sẽ hoàn thành trước một mốc tương lai.', 'order_index': 11},
      {'name': 'Future Perfect Continuous', 'name_vi': 'Tương lai hoàn thành tiếp diễn', 'category': 'future', 'formula': 'S + will have been + V-ing', 'signal_words': 'for, by the time, until', 'example_pos': 'By 2027, she will have been teaching for 10 years.', 'example_neg': 'She will not have been working there long.', 'example_que': 'Will she have been living here for 5 years by then?', 'theory': '## Tương lai hoàn thành tiếp diễn\nNhấn mạnh tính liên tục đến một mốc tương lai.', 'order_index': 12},
    ];

    for (final t in tenses) {
      await db.insert('grammar_topics', t);
    }
  }
}