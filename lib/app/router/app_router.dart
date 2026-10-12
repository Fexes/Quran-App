import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/shell/presentation/pages/shell_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/hifz/presentation/pages/hifz_dashboard_page.dart';
import '../../features/hifz/presentation/pages/hifz_review_page.dart';
import '../../features/azkar/presentation/pages/azkar_category_page.dart';
import '../../features/backup/presentation/pages/backup_page.dart';
import '../../features/hadith/presentation/pages/hadith_book_page.dart';
import '../../features/quran/presentation/pages/quran_bookmarks_page.dart';
import '../../features/quran/presentation/pages/quran_notes_page.dart';
import '../../features/quran/presentation/pages/quran_reader_page.dart';
import '../../features/quran/presentation/pages/quran_translation_manager_page.dart';
import '../../features/quran/presentation/pages/search/quran_search_page.dart';
import '../../features/quran_audio/presentation/pages/quran_downloads_page.dart';
import '../../features/reading_goals/presentation/pages/reading_goals_page.dart';
import '../../features/prayer_tracking/presentation/pages/prayer_tracking_page.dart';
import '../../features/qibla/presentation/pages/qibla_page.dart';
import '../../features/worship_tools/presentation/pages/achievements_page.dart';
import '../../features/worship_tools/presentation/pages/divine_names_page.dart';
import '../../features/worship_tools/presentation/pages/duas_page.dart';
import '../../features/worship_tools/presentation/pages/mosque_locator_page.dart';
import '../../features/worship_tools/presentation/pages/ramadan_page.dart';
import '../../features/worship_tools/presentation/pages/zakat_page.dart';
import '../../features/tasbieh/presentation/pages/tasbieh_page.dart';
import '../../core/storage/settings_store.dart';
import '../di/injection.dart';
import 'app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.shell,
  redirect: (context, state) {
    if (!getIt.isRegistered<SettingsStore>()) {
      return null;
    }
    final store = getIt<SettingsStore>();
    final onOnboarding = state.uri.path == AppRoutes.onboarding;
    final editing = state.uri.queryParameters['edit'] == 'true';
    if (store.shouldShowOnboarding && !onOnboarding) {
      return AppRoutes.onboarding;
    }
    if (!store.shouldShowOnboarding && onOnboarding && !editing) {
      return AppRoutes.shell;
    }
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) =>
          OnboardingPage(editMode: state.uri.queryParameters['edit'] == 'true'),
    ),
    GoRoute(
      path: AppRoutes.shell,
      name: 'shell',
      builder: (context, state) => const ShellPage(),
    ),
    GoRoute(
      path: AppRoutes.quranReader,
      name: 'quran-reader',
      builder: (context, state) {
        final raw = state.pathParameters['surahNumber'] ?? '1';
        final surahNumber = int.tryParse(raw) ?? 1;
        final ayahNumber = int.tryParse(
          state.uri.queryParameters['ayah'] ?? '',
        );
        return QuranReaderPage(
          surahNumber: surahNumber,
          initialAyahNumber: ayahNumber,
          initialTranslationResourceId: int.tryParse(
            state.uri.queryParameters['translation'] ?? '',
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.quranSearch,
      name: 'quran-search',
      builder: (context, state) {
        return QuranSearchPage(
          initialQuery: state.uri.queryParameters['query'],
        );
      },
    ),
    GoRoute(
      path: AppRoutes.quranDownloads,
      name: 'quran-downloads',
      builder: (context, state) => QuranDownloadsPage(
        showTranslations: state.uri.queryParameters['type'] == 'translation',
      ),
    ),
    GoRoute(
      path: AppRoutes.quranTranslations,
      name: 'quran-translations',
      builder: (context, state) => const QuranTranslationManagerPage(),
    ),
    GoRoute(
      path: AppRoutes.quranBookmarks,
      name: 'quran-bookmarks',
      builder: (context, state) => const QuranBookmarksPage(),
    ),
    GoRoute(
      path: AppRoutes.quranNotes,
      name: 'quran-notes',
      builder: (context, state) {
        return QuranNotesPage(initialNoteId: state.uri.queryParameters['note']);
      },
    ),
    GoRoute(
      path: AppRoutes.readingGoals,
      name: 'reading-goals',
      builder: (context, state) => const ReadingGoalsPage(),
    ),
    GoRoute(
      path: AppRoutes.hifz,
      name: 'hifz',
      builder: (context, state) => const HifzDashboardPage(),
    ),
    GoRoute(
      path: AppRoutes.hifzReview,
      name: 'hifz-review',
      builder: (context, state) => HifzReviewPage(
        collectionId: state.pathParameters['collectionId'] ?? '',
      ),
    ),
    GoRoute(
      path: AppRoutes.backup,
      name: 'backup',
      builder: (context, state) => const BackupPage(),
    ),
    GoRoute(
      path: AppRoutes.prayerTracking,
      name: 'prayer-tracking',
      builder: (context, state) => const PrayerTrackingPage(),
    ),
    GoRoute(
      path: AppRoutes.qibla,
      name: 'qibla',
      builder: (context, state) => const QiblaPage(),
    ),
    GoRoute(
      path: AppRoutes.fastingJournal,
      name: 'fasting-journal',
      builder: (context, state) => const PrayerTrackingPage(fastingOnly: true),
    ),
    GoRoute(
      path: AppRoutes.duas,
      name: 'duas',
      builder: (context, state) => const DuasPage(),
    ),
    GoRoute(
      path: AppRoutes.divineNames,
      name: 'divine-names',
      builder: (context, state) => const DivineNamesPage(),
    ),
    GoRoute(
      path: AppRoutes.zakat,
      name: 'zakat',
      builder: (context, state) => const ZakatPage(),
    ),
    GoRoute(
      path: AppRoutes.ramadan,
      name: 'ramadan',
      builder: (context, state) => const RamadanPage(),
    ),
    GoRoute(
      path: AppRoutes.achievements,
      name: 'achievements',
      builder: (context, state) => const AchievementsPage(),
    ),
    GoRoute(
      path: AppRoutes.mosques,
      name: 'mosques',
      builder: (context, state) => const MosqueLocatorPage(),
    ),
    GoRoute(
      path: AppRoutes.hadithBook,
      name: 'hadith-book',
      builder: (context, state) {
        return HadithBookPage(
          bookId: state.pathParameters['bookId'] ?? '',
          initialLookup: state.uri.queryParameters['hadith'],
        );
      },
    ),
    GoRoute(
      path: AppRoutes.azkarCategory,
      name: 'azkar-category',
      builder: (context, state) {
        return AzkarCategoryPage(
          categoryId: state.pathParameters['categoryId'] ?? '',
          initialItemId: state.uri.queryParameters['item'],
        );
      },
    ),
    GoRoute(
      path: AppRoutes.tasbieh,
      name: 'tasbieh',
      builder: (context, state) => const TasbiehPage(),
    ),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      body: Center(child: Text(state.error?.message ?? 'Route not found')),
    );
  },
);
