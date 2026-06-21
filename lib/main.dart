// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/providers/auth_provider.dart';
import 'core/providers/vocabulary_provider.dart';
import 'core/providers/grammar_provider.dart';
import 'core/providers/lesson_provider.dart';
import 'core/providers/progress_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/roadmap_provider.dart';
import 'core/providers/submission_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/database/database_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/main/main_scaffold.dart';
import 'features/vocabulary/flashcard_screen.dart';
import 'features/vocabulary/saved_words_screen.dart';
import 'features/vocabulary/word_quiz_screen.dart';
import 'features/grammar/grammar_list_screen.dart';
import 'features/grammar/grammar_detail_screen.dart';
import 'features/grammar/grammar_exercise_screen.dart';
import 'features/reading/reading_list_screen.dart';
import 'features/reading/reading_detail_screen.dart';
import 'features/listening/listening_list_screen.dart';
import 'features/listening/listening_exercise_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/settings_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/admin/admin_lesson_form_screen.dart';
import 'features/admin/admin_vocab_form_screen.dart';
import 'features/admin/admin_user_list_screen.dart';
import 'features/roadmap/roadmap_screen.dart';
import 'features/roadmap/roadmap_setup_screen.dart';
import 'features/writing/writing_list_screen.dart';
import 'features/writing/writing_exercise_screen.dart';
import 'features/writing/my_submissions_screen.dart';
import 'features/admin/admin_lesson_list_screen.dart';
import 'features/admin/admin_grading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Khởi tạo DB trước
  await DatabaseHelper.instance.database;

  // Firebase không block nếu lỗi
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}

  runApp(const EnglishApp());
}

class EnglishApp extends StatelessWidget {
  const EnglishApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProvider(create: (_) => VocabularyProvider()),
        ChangeNotifierProvider(create: (_) => GrammarProvider()),
        // LessonProvider tự load ngay khi tạo
        ChangeNotifierProvider(create: (_) => LessonProvider()..loadAll()),
        ChangeNotifierProxyProvider<AuthProvider, RoadmapProvider>(
          create: (_) => RoadmapProvider(),
          update: (_, auth, prev) => prev!,
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProgressProvider>(
          create: (_) => ProgressProvider(),
          update: (_, auth, prev) => prev!..onAuthChanged(auth.currentUser?.id),
        ),
        ChangeNotifierProvider(create: (_) => SubmissionProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, tp, __) => MaterialApp(
          title: 'Hungo English',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: tp.themeMode,
          initialRoute: '/splash',
          routes: {
            '/splash':            (_) => const SplashScreen(),
            '/login':             (_) => const LoginScreen(),
            '/register':          (_) => const RegisterScreen(),
            '/home':              (_) => const MainScaffold(),
            '/vocab/flashcard':   (_) => const FlashcardScreen(),
            '/vocab/saved':       (_) => const SavedWordsScreen(),
            '/vocab/quiz':        (_) => const WordQuizScreen(),
            '/grammar':           (_) => const GrammarListScreen(),
            '/grammar/detail':    (c) => GrammarDetailScreen(
                topic: ModalRoute.of(c)!.settings.arguments as dynamic),
            '/grammar/exercise':  (c) {
              final args = ModalRoute.of(c)!.settings.arguments as Map;
              return GrammarExerciseScreen(
                grammarTopic: args['grammarTopic'] as String,
                grammarName: args['grammarName'] as String,
              );
            },
            '/reading':           (_) => const ReadingListScreen(),
            '/reading/detail':    (c) => ReadingDetailScreen(
                lesson: ModalRoute.of(c)!.settings.arguments as dynamic),
            '/listening':         (_) => const ListeningListScreen(),
            '/listening/exercise':(c) => ListeningExerciseScreen(
                lesson: ModalRoute.of(c)!.settings.arguments as dynamic),
            '/writing':           (_) => const WritingListScreen(),
            '/writing/exercise':  (c) => WritingExerciseScreen(
                lesson: ModalRoute.of(c)!.settings.arguments as dynamic),
            '/profile':           (_) => const ProfileScreen(),
            '/settings':          (_) => const SettingsScreen(),
            '/roadmap':           (_) => const RoadmapScreen(),
            '/roadmap/setup':     (_) => const RoadmapSetupScreen(),
            '/admin':             (_) => const AdminDashboardScreen(),
            '/admin/lesson':      (c) => AdminLessonFormScreen(
                lesson: ModalRoute.of(c)!.settings.arguments),
            '/admin/vocab':       (_) => const AdminVocabFormScreen(),
            '/admin/users':       (_) => const AdminUserListScreen(),
            '/admin/lessons':     (_) => const AdminLessonListScreen(),
            '/my-submissions':  (_) => const MySubmissionsScreen(),
            '/admin/grading':   (_) => const AdminGradingScreen(),
          },
        ),
      ),
    );
  }
}
