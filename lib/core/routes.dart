import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/level_selection_screen.dart';
import '../screens/roadmap_screen.dart';
import '../screens/topic_selection_screen.dart';
import '../screens/vocabulary_screen.dart';
import '../screens/vocabulary_list_screen.dart';
import '../screens/flashcard_screen.dart';
import '../screens/profile_selection_screen.dart';
import '../screens/practice_test_list_screen.dart';
import '../screens/practice_quiz_screen.dart';
import '../screens/practice_result_screen.dart';
import '../screens/exam_rules_screen.dart';
import '../screens/formal_exam_screen.dart';
import '../screens/exam_result_screen.dart';
import '../screens/exam_history_screen.dart';
import '../screens/exam_history_detail_screen.dart';
import '../screens/account_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/settings_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String levelSelection = '/level-selection';
  static const String roadmap = '/roadmap';
  static const String vocabulary = '/vocabulary';
  static const String topicSelection = '/topic-selection';
  static const String vocabularyList = '/vocabulary-list';
  static const String flashcard = '/flashcard';
  static const String profileSelection = '/profile-selection';
  static const String practiceTestList = '/practice-test-list';
  static const String practiceQuiz = '/practice-quiz';
  static const String practiceResult = '/practice-result';
  static const String examRules = '/exam-rules';
  static const String formalExam = '/formal-exam';
  static const String examResult = '/exam-result';
  static const String examHistory = '/exam-history';
  static const String examHistoryDetail = '/exam-history-detail';
  static const String account = '/account';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return _buildRoute(const SplashScreen());
      case welcome:
        return _buildRoute(const WelcomeScreen());
      case login:
        return _buildRoute(const LoginScreen());
      case register:
        return _buildRoute(const RegisterScreen());
      case onboarding:
        return _buildRoute(const OnboardingScreen());
      case levelSelection:
        return _buildRoute(const LevelSelectionScreen());
      case roadmap:
        return _buildRoute(const RoadmapScreen());
      case vocabulary:
        return _buildRoute(const VocabularyScreen());
      case topicSelection:
        return _buildRoute(const TopicSelectionScreen());
      case vocabularyList:
        return _buildRoute(const VocabularyListScreen());
      case flashcard:
        final args = routeSettings.arguments;
        if (args is Map<String, dynamic> && args['topicId'] is int) {
          return _buildRoute(
            FlashcardScreen(
              topicId: args['topicId'] as int,
              topicName: args['topicName']?.toString(),
            ),
          );
        }
        return _buildRoute(const SplashScreen());
      case profileSelection:
        return _buildRoute(const ProfileSelectionScreen());
      case practiceTestList:
        return _buildRoute(const PracticeTestListScreen());
      case practiceQuiz:
        final args = routeSettings.arguments;
        if (args is Map<String, dynamic>) {
          return _buildRoute(
            PracticeQuizScreen(
              testId: args['testId'] as int,
              resultId: args['resultId'] as int,
              testName: args['testName']?.toString() ?? 'Luyện tập',
              totalQuestions: args['totalQuestions'] as int?,
            ),
          );
        }
        return _buildRoute(const SplashScreen());
      case practiceResult:
        final args = routeSettings.arguments;
        if (args is Map<String, dynamic>) {
          final score = args['score'] as int? ?? 0;
          final total = args['totalQuestions'] as int? ?? 0;
          final correct = args['correctCount'] as int?;
          final wrong = args['wrongCount'] as int?;
          final correctCount = correct ?? (total > 0 ? ((score / 100.0) * total).round() : 0);
          final wrongCount = wrong ?? (total - correctCount);
          return _buildRoute(
            PracticeResultScreen(
              score: score,
              correctCount: correctCount,
              wrongCount: wrongCount,
              totalQuestions: total,
              isPassed: args['isPassed'] as bool? ?? false,
              testId: args['testId'] as int?,
              testName: args['testName']?.toString(),
            ),
          );
        }
        return _buildRoute(const SplashScreen());
      case examRules:
        return _buildRoute(const ExamRulesScreen());
      case formalExam:
        return _buildRoute(const FormalExamScreen());
      case examResult:
        return _buildRoute(const ExamResultScreen());
      case examHistory:
        return _buildRoute(const ExamHistoryScreen());
      case examHistoryDetail:
        final args = routeSettings.arguments;
        if (args is Map<String, dynamic> && args['resultId'] != null && args['profileId'] != null) {
          return _buildRoute(ExamHistoryDetailScreen(
            resultId: args['resultId'] as int,
            profileId: args['profileId'] as int,
          ));
        }
        return _buildRoute(const SplashScreen());
      case account:
        return _buildRoute(const AccountScreen());
      case editProfile:
        return _buildRoute(const EditProfileScreen());
      case settings:
        return _buildRoute(const SettingsScreen());
      default:
        return _buildRoute(const SplashScreen());
    }
  }

  static MaterialPageRoute _buildRoute(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
