// lib/features/listening/listening_exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../core/providers/lesson_provider.dart';
import '../../core/providers/progress_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class ListeningExerciseScreen extends StatefulWidget {
  final dynamic lesson;
  const ListeningExerciseScreen({super.key, required this.lesson});
  @override
  State<ListeningExerciseScreen> createState() => _ListeningExerciseScreenState();
}

class _ListeningExerciseScreenState extends State<ListeningExerciseScreen>
    with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  final _tts    = FlutterTts();

  PlayerState _playerState = PlayerState.stopped;
  Duration    _duration    = Duration.zero;
  Duration    _position    = Duration.zero;
  bool _hasListened = false;
  int  _playCount   = 0;
  bool _showScript  = false;
  bool _isBuffering = false; // đang load file

  // Animation cho nút play (pulse effect)
  late AnimationController _pulseCtrl;
  late Animation<double>    _pulseAnim;

  final Map<int, TextEditingController> _ctrls   = {};
  final Map<int, bool>                  _results = {};
  bool _submitted = false;
  int  _score     = 0;
  final _startTime = DateTime.now();

  LessonModel get _lesson => widget.lesson as LessonModel;
  bool get _hasRealAudio =>
      _lesson.audioUrl != null && _lesson.audioUrl!.isNotEmpty;

  // ── Init ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    // Pulse animation khi đang phát
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _pulseAnim = Tween(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _initAudio();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LessonProvider>().loadQuestions(_lesson.id!);
    });
  }

  Future<void> _initAudio() async {
    if (_hasRealAudio) {
      _player.onPlayerStateChanged.listen((s) {
        if (!mounted) return;
        setState(() => _playerState = s);
        if (s == PlayerState.playing) {
          _pulseCtrl.repeat(reverse: true);
        } else {
          _pulseCtrl.stop();
          _pulseCtrl.reset();
        }
      });
      _player.onDurationChanged.listen((d) {
        if (mounted) setState(() { _duration = d; _isBuffering = false; });
      });
      _player.onPositionChanged.listen((p) {
        if (mounted) setState(() => _position = p);
      });
      _player.onPlayerComplete.listen((_) {
        if (!mounted) return;
        setState(() {
          _playerState = PlayerState.stopped;
          _position    = Duration.zero;
          _isBuffering = false;
        });
        _pulseCtrl.stop();
        _pulseCtrl.reset();
      });
    } else {
      // TTS fallback
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.42);
      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() => _playerState = PlayerState.stopped);
          _pulseCtrl.stop();
          _pulseCtrl.reset();
        }
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _tts.stop();
    _pulseCtrl.dispose();
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  // ── Play / Pause — KHÔNG cho tua ─────────────────────────────────────────
  Future<void> _togglePlay() async {
    if (_hasRealAudio) {
      if (_playerState == PlayerState.playing) {
        // Pause
        await _player.pause();
      } else {
        setState(() { _hasListened = true; _isBuffering = true; });
        if (_playerState == PlayerState.paused) {
          // Resume từ vị trí pause (không reset về đầu)
          await _player.resume();
        } else {
          // Play từ đầu
          _playCount++;
          final url = _lesson.audioUrl!;
          if (url.startsWith('/')) {
            await _player.play(DeviceFileSource(url));
          } else if (url.startsWith('assets/')) {
            await _player.play(
                AssetSource(url.replaceFirst('assets/', '')));
          } else {
            await _player.play(UrlSource(url));
          }
        }
      }
    } else {
      // TTS fallback
      if (_playerState == PlayerState.playing) {
        await _tts.stop();
        setState(() => _playerState = PlayerState.stopped);
      } else {
        _playCount++;
        setState(() {
          _playerState  = PlayerState.playing;
          _hasListened  = true;
        });
        await _tts.speak(_lesson.content ?? _lesson.title);
      }
    }
  }

  String _fmtDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progressValue {
    if (_duration.inSeconds == 0) return 0;
    return (_position.inSeconds / _duration.inSeconds).clamp(0.0, 1.0);
  }

  // ── Nộp bài ──────────────────────────────────────────────────────────────
  void _submit(List<QuestionModel> questions) {
    int s = 0;
    final results = <int, bool>{};
    for (int i = 0; i < questions.length; i++) {
      final ans     = (_ctrls[i]?.text ?? '').trim().toLowerCase();
      final correct = questions[i].correctAnswer.trim().toLowerCase();
      final ok      = ans == correct;
      results[i] = ok;
      if (ok) s += questions[i].points;
    }
    setState(() {
      _results.addAll(results);
      _score     = s;
      _submitted = true;
      _showScript = true;
    });

    final auth    = context.read<AuthProvider>();
    final prog    = context.read<ProgressProvider>();
    final maxScore = questions.fold<int>(0, (a, q) => a + q.points);
    final secs    = DateTime.now().difference(_startTime).inSeconds;
    if (auth.isLoggedIn) {
      prog.saveProgress(
        skill: 'listening', lessonId: _lesson.id,
        score: s, maxScore: maxScore, timeSpent: secs,
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Kết quả', textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$s / $maxScore',
              style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold,
                  color: AppTheme.skillListening)),
          const SizedBox(height: 8),
          Text('${results.values.where((v) => v).length}/${questions.length} câu đúng'),
          const SizedBox(height: 4),
          Text('Nghe $_playCount lần · ${secs}s',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ]),
        actions: [
          TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('Thoát')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _submitted  = false; _score = 0;
                  _results.clear(); _hasListened = false;
                  _playCount  = 0;   _showScript = false;
                  for (final c in _ctrls.values) c.clear();
                });
              },
              child: const Text('Làm lại')),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final lp        = context.watch<LessonProvider>();
    final questions = lp.questions;
    for (int i = 0; i < questions.length; i++) {
      _ctrls.putIfAbsent(i, () => TextEditingController());
    }

    final isPlaying = _playerState == PlayerState.playing;
    final isPaused  = _playerState == PlayerState.paused;

    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson.title, overflow: TextOverflow.ellipsis),
        backgroundColor: AppTheme.skillListening,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── AUDIO PLAYER CARD ─────────────────────────────────────
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [AppTheme.skillListening, Color(0xFFBF360C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(children: [
                  // Icon + title
                  const Icon(Icons.headphones_rounded,
                      color: Colors.white, size: 40),
                  const SizedBox(height: 10),
                  Text(_lesson.title,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 15, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                          _hasRealAudio ? '🎵 Audio' : '🔊 TTS',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    Text('Nghe: $_playCount lần',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ]),
                  const SizedBox(height: 20),

                  // ── THANH TIẾN TRÌNH (chỉ hiển thị, KHÔNG tua được) ──
                  if (_hasRealAudio) ...[
                    // Label thời gian
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmtDuration(_position),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                          if (_isBuffering)
                            const Text('Đang tải...',
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 11))
                          else if (_duration > Duration.zero)
                            Text(_fmtDuration(_duration),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Thanh progress — CHỈ ĐỌC, không tua
                    Stack(children: [
                      // Background track
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      // Progress fill
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 6,
                        width: _progressValue *
                            (MediaQuery.of(context).size.width - 80),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),

                    // Buffering indicator
                    if (_isBuffering)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                          minHeight: 2,
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],

                  // ── NÚT PLAY / PAUSE ────────────────────────────────
                  ScaleTransition(
                    scale: isPlaying ? _pulseAnim
                        : const AlwaysStoppedAnimation(1.0),
                    child: GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? Colors.white
                              : isPaused
                              ? Colors.white70
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _isBuffering
                            ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: AppTheme.skillListening,
                            strokeWidth: 3,
                          ),
                        )
                            : Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: AppTheme.skillListening,
                          size: 44,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isBuffering
                        ? 'Đang tải file...'
                        : isPlaying
                        ? 'Đang phát ▶'
                        : isPaused
                        ? 'Đã tạm dừng ⏸'
                        : 'Nhấn để nghe',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 13),
                  ),

                  // Lưu ý không tua
                  if (_hasRealAudio && !_submitted) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '⚠ Bài nghe không thể tua — hãy chú ý lắng nghe',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // ── SCRIPT (sau khi nộp bài) ──────────────────────────────
            if (_showScript &&
                _lesson.content != null &&
                _lesson.content!.isNotEmpty) ...[
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.article_outlined,
                            color: AppTheme.skillListening),
                        SizedBox(width: 8),
                        Text('Script bài nghe',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ]),
                      const Divider(height: 16),
                      Text(_lesson.content!,
                          style: const TextStyle(
                              fontSize: 14, height: 1.7)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── CHƯA NGHE ─────────────────────────────────────────────
            if (!_hasListened)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Nghe bài audio trước khi làm bài tập bên dưới'),
                  ),
                ]),
              ),

            // ── CÂU HỎI ──────────────────────────────────────────────
            if (_hasListened && questions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Câu hỏi (${questions.length} câu)',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              ...List.generate(questions.length, (i) {
                final q      = questions[i];
                final ctrl   = _ctrls[i]!;
                final result = _results[i];

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Câu ${i+1}: ${q.questionText}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15, height: 1.5)),
                        const SizedBox(height: 12),

                        // MCQ
                        if (q.questionType == 'mcq' &&
                            q.options != null)
                          ...q.options!.map((opt) {
                            Color? bg, border;
                            if (_submitted) {
                              if (opt == q.correctAnswer) {
                                bg = Colors.green.shade50;
                                border = Colors.green;
                              } else if (opt == ctrl.text) {
                                bg = Colors.red.shade50;
                                border = Colors.red;
                              }
                            }
                            return GestureDetector(
                              onTap: _submitted
                                  ? null
                                  : () => setState(() => ctrl.text = opt),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 11),
                                decoration: BoxDecoration(
                                  color: bg ?? (ctrl.text == opt
                                      ? AppTheme.skillListening
                                      .withOpacity(0.1)
                                      : null),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: border ?? (ctrl.text == opt
                                        ? AppTheme.skillListening
                                        : Colors.grey.shade300),
                                    width: border != null ||
                                        ctrl.text == opt
                                        ? 2 : 1,
                                  ),
                                ),
                                child: Row(children: [
                                  Expanded(child: Text(opt)),
                                  if (_submitted &&
                                      opt == q.correctAnswer)
                                    const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.green, size: 18),
                                ]),
                              ),
                            );
                          }),

                        // Fill blank
                        if (q.questionType == 'fill_blank')
                          TextField(
                            controller: ctrl,
                            enabled: !_submitted,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Điền câu trả lời',
                              prefixIcon:
                              const Icon(Icons.edit_outlined),
                              suffixIcon: _submitted
                                  ? Icon(
                                  result == true
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color: result == true
                                      ? Colors.green
                                      : Colors.red)
                                  : null,
                            ),
                          ),

                        if (_submitted && result == false) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.green.shade200),
                            ),
                            child: Row(children: [
                              const Icon(Icons.check_rounded,
                                  color: Colors.green, size: 16),
                              const SizedBox(width: 6),
                              Text('Đáp án: ${q.correctAnswer}',
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),

              if (!_submitted)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _ctrls.values
                        .every((c) => c.text.isNotEmpty)
                        ? () => _submit(questions)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.skillListening,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Nộp bài'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}