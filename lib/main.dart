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
import 'core/theme/app_theme.dart';
import 'core/database/database_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/main/main_scaffold.dart';
import 'features/vocabulary/search_screen.dart';
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
import 'features/admin/admin_lesson_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Chạy song song để không block UI
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    DatabaseHelper.instance.database,
  ]);
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
        ChangeNotifierProvider(create: (_) => LessonProvider()),
        ChangeNotifierProxyProvider<AuthProvider, RoadmapProvider>(
          create: (_) => RoadmapProvider(),
          update: (_, auth, prev) => prev!,
        ),
        ChangeNotifierProxyProvider<AuthProvider, ProgressProvider>(
          create: (_) => ProgressProvider(),
          update: (_, auth, prev) => prev!..onAuthChanged(auth.currentUser?.id),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, tp, __) => MaterialApp(
          title: 'EnglishMate',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: tp.themeMode,
          initialRoute: '/',
          onGenerateRoute: _route,
        ),
      ),
    );
  }

  static Route<dynamic> _route(RouteSettings s) {
    Widget page;
    switch (s.name) {
      case '/':           page = const SplashScreen(); break;
      case '/login':      page = const LoginScreen(); break;
      case '/register':   page = const RegisterScreen(); break;
      case '/home':       page = const MainScaffold(); break;
      case '/vocab/search':    page = const SearchScreen(); break;
      case '/vocab/flashcard': page = const FlashcardScreen(); break;
      case '/vocab/saved':     page = const SavedWordsScreen(); break;
      case '/vocab/quiz':      page = const WordQuizScreen(); break;
      case '/grammar':         page = const GrammarListScreen(); break;
      case '/grammar/detail':
        page = GrammarDetailScreen(topic: s.arguments); break;
      case '/grammar/exercise':
        final a = s.arguments as Map<String, dynamic>;
        page = GrammarExerciseScreen(grammarId: a['grammarId'], grammarName: a['grammarName']);
        break;
      case '/reading':         page = const ReadingListScreen(); break;
      case '/reading/detail':
        page = ReadingDetailScreen(lesson: s.arguments); break;
      case '/listening':       page = const ListeningListScreen(); break;
      case '/listening/exercise':
        page = ListeningExerciseScreen(lesson: s.arguments); break;
      case '/profile':         page = const ProfileScreen(); break;
      case '/settings':        page = const SettingsScreen(); break;
      case '/admin':           page = const AdminDashboardScreen(); break;
      case '/admin/lesson':
        page = AdminLessonFormScreen(lesson: s.arguments); break;
      case '/admin/vocab':     page = const AdminVocabFormScreen(); break;
      case '/admin/users':     page = const AdminUserListScreen(); break;
      case '/roadmap':         page = const RoadmapScreen(); break;
      case '/roadmap/setup':   page = const RoadmapSetupScreen(); break;
      case '/writing':         page = const WritingListScreen(); break;
      case '/writing/exercise':
        page = WritingExerciseScreen(lesson: s.arguments); break;
      case '/admin/lessons':   page = const AdminLessonListScreen(); break;
      default:
        page = Scaffold(body: Center(child: Text('404: \${s.name}')));
    }
    return PageRouteBuilder(
      settings: s,
      pageBuilder: (_, a, __) => page,
      transitionsBuilder: (_, a, __, child) =>
          FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeIn), child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
