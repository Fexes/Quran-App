import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('ur'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get appTitle;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Assalamu alaikum'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read, remember, and prepare for prayer from one calm place.'**
  String get homeSubtitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabQuran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get tabQuran;

  /// No description provided for @tabPrayer.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get tabPrayer;

  /// No description provided for @tabLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get tabLibrary;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @nextPrayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Next prayer'**
  String get nextPrayerTitle;

  /// No description provided for @nextPrayerName.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get nextPrayerName;

  /// No description provided for @nextPrayerTime.
  ///
  /// In en, this message translates to:
  /// **'12:35'**
  String get nextPrayerTime;

  /// No description provided for @continueReadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get continueReadingTitle;

  /// No description provided for @continueReadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Surah Al-Fatihah, Ayah 1'**
  String get continueReadingSubtitle;

  /// No description provided for @continueReadingEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start with Surah Al-Fatihah'**
  String get continueReadingEmptySubtitle;

  /// No description provided for @ayahLabel.
  ///
  /// In en, this message translates to:
  /// **'Ayah'**
  String get ayahLabel;

  /// No description provided for @dailyAyahTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily ayah'**
  String get dailyAyahTitle;

  /// No description provided for @dailyAyahText.
  ///
  /// In en, this message translates to:
  /// **'ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ'**
  String get dailyAyahText;

  /// No description provided for @dailyAyahReference.
  ///
  /// In en, this message translates to:
  /// **'Al-Fatihah 1:6'**
  String get dailyAyahReference;

  /// No description provided for @quickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActionsTitle;

  /// No description provided for @actionQuran.
  ///
  /// In en, this message translates to:
  /// **'Read Quran'**
  String get actionQuran;

  /// No description provided for @actionQibla.
  ///
  /// In en, this message translates to:
  /// **'Qibla'**
  String get actionQibla;

  /// No description provided for @actionAzkar.
  ///
  /// In en, this message translates to:
  /// **'Azkar'**
  String get actionAzkar;

  /// No description provided for @actionMosque.
  ///
  /// In en, this message translates to:
  /// **'Mosques'**
  String get actionMosque;

  /// No description provided for @quranTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quranTitle;

  /// No description provided for @quranSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Surahs, juz, bookmarks, and search.'**
  String get quranSubtitle;

  /// No description provided for @quranSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by surah name or number'**
  String get quranSearchHint;

  /// No description provided for @quranTextSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search Quran text'**
  String get quranTextSearchHint;

  /// No description provided for @quranOpenTextSearch.
  ///
  /// In en, this message translates to:
  /// **'Search Quran text'**
  String get quranOpenTextSearch;

  /// No description provided for @quranNoResults.
  ///
  /// In en, this message translates to:
  /// **'No surahs found.'**
  String get quranNoResults;

  /// No description provided for @quranReaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Reader'**
  String get quranReaderTitle;

  /// No description provided for @quranSearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Quran'**
  String get quranSearchTitle;

  /// No description provided for @quranSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching Quran'**
  String get quranSearching;

  /// No description provided for @quranSearchPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Search the Quran'**
  String get quranSearchPromptTitle;

  /// No description provided for @quranSearchPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter an Arabic word or phrase to find matching ayahs.'**
  String get quranSearchPromptSubtitle;

  /// No description provided for @quranNoSearchResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No ayahs found'**
  String get quranNoSearchResultsTitle;

  /// No description provided for @quranNoSearchResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try a shorter Arabic word or another phrase.'**
  String get quranNoSearchResultsSubtitle;

  /// No description provided for @quranSearchFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get quranSearchFailedTitle;

  /// No description provided for @loadingQuran.
  ///
  /// In en, this message translates to:
  /// **'Loading Quran'**
  String get loadingQuran;

  /// No description provided for @quranLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran could not be loaded'**
  String get quranLoadFailedTitle;

  /// No description provided for @quranLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get quranLoadFailedMessage;

  /// No description provided for @quranAudioTitle.
  ///
  /// In en, this message translates to:
  /// **'Reciter'**
  String get quranAudioTitle;

  /// No description provided for @quranPlayAyahAudio.
  ///
  /// In en, this message translates to:
  /// **'Play ayah audio'**
  String get quranPlayAyahAudio;

  /// No description provided for @quranPlaySurahAudio.
  ///
  /// In en, this message translates to:
  /// **'Play Surah'**
  String get quranPlaySurahAudio;

  /// No description provided for @quranStopAudio.
  ///
  /// In en, this message translates to:
  /// **'Stop audio'**
  String get quranStopAudio;

  /// No description provided for @quranAudioLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Audio could not be played. Check your connection and try another reciter.'**
  String get quranAudioLoadFailed;

  /// No description provided for @quranAudioOpenAyah.
  ///
  /// In en, this message translates to:
  /// **'Open ayah'**
  String get quranAudioOpenAyah;

  /// No description provided for @quranAudioSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get quranAudioSpeed;

  /// No description provided for @quranAudioRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get quranAudioRepeat;

  /// No description provided for @quranAudioRepeatOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get quranAudioRepeatOff;

  /// No description provided for @quranAudioRepeatAyah.
  ///
  /// In en, this message translates to:
  /// **'Ayah'**
  String get quranAudioRepeatAyah;

  /// No description provided for @quranAudioRepeatSurah.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get quranAudioRepeatSurah;

  /// No description provided for @quranAudioRepeatCount.
  ///
  /// In en, this message translates to:
  /// **'Repeat count'**
  String get quranAudioRepeatCount;

  /// No description provided for @quranAudioRepeatOnce.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get quranAudioRepeatOnce;

  /// No description provided for @quranAudioRepeatTwo.
  ///
  /// In en, this message translates to:
  /// **'2 times'**
  String get quranAudioRepeatTwo;

  /// No description provided for @quranAudioRepeatThree.
  ///
  /// In en, this message translates to:
  /// **'3 times'**
  String get quranAudioRepeatThree;

  /// No description provided for @quranAudioRepeatFive.
  ///
  /// In en, this message translates to:
  /// **'5 times'**
  String get quranAudioRepeatFive;

  /// No description provided for @quranAudioRepeatTen.
  ///
  /// In en, this message translates to:
  /// **'10 times'**
  String get quranAudioRepeatTen;

  /// No description provided for @quranAudioRangeFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get quranAudioRangeFrom;

  /// No description provided for @quranAudioRangeTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get quranAudioRangeTo;

  /// No description provided for @quranAudioPlayRange.
  ///
  /// In en, this message translates to:
  /// **'Play range'**
  String get quranAudioPlayRange;

  /// No description provided for @quranAudioPresetCurrentAyah.
  ///
  /// In en, this message translates to:
  /// **'Current ayah'**
  String get quranAudioPresetCurrentAyah;

  /// No description provided for @quranAudioPresetCurrentPage.
  ///
  /// In en, this message translates to:
  /// **'Current page'**
  String get quranAudioPresetCurrentPage;

  /// No description provided for @quranAudioPresetToEnd.
  ///
  /// In en, this message translates to:
  /// **'To end'**
  String get quranAudioPresetToEnd;

  /// No description provided for @quranAudioPresetFullSurah.
  ///
  /// In en, this message translates to:
  /// **'Full Surah'**
  String get quranAudioPresetFullSurah;

  /// No description provided for @translationToggleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle translation'**
  String get translationToggleTooltip;

  /// No description provided for @increaseQuranFontTooltip.
  ///
  /// In en, this message translates to:
  /// **'Increase Quran font'**
  String get increaseQuranFontTooltip;

  /// No description provided for @decreaseQuranFontTooltip.
  ///
  /// In en, this message translates to:
  /// **'Decrease Quran font'**
  String get decreaseQuranFontTooltip;

  /// No description provided for @bookmarkAyahTooltip.
  ///
  /// In en, this message translates to:
  /// **'Bookmark ayah'**
  String get bookmarkAyahTooltip;

  /// No description provided for @removeBookmarkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get removeBookmarkTooltip;

  /// No description provided for @markLastReadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark as last read'**
  String get markLastReadTooltip;

  /// No description provided for @bookmarksTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarksTitle;

  /// No description provided for @bookmarksLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading bookmarks'**
  String get bookmarksLoading;

  /// No description provided for @bookmarksEmpty.
  ///
  /// In en, this message translates to:
  /// **'Bookmark an ayah to see it here.'**
  String get bookmarksEmpty;

  /// No description provided for @contentSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get contentSourceLabel;

  /// No description provided for @prayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer'**
  String get prayerTitle;

  /// No description provided for @prayerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer times, Qibla, calendar, and nearby mosques.'**
  String get prayerSubtitle;

  /// No description provided for @prayerTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer times'**
  String get prayerTimesTitle;

  /// No description provided for @qiblaTitle.
  ///
  /// In en, this message translates to:
  /// **'Qibla direction'**
  String get qiblaTitle;

  /// No description provided for @qiblaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find the direction of the Kaaba.'**
  String get qiblaSubtitle;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Islamic calendar'**
  String get calendarTitle;

  /// No description provided for @mosqueTitle.
  ///
  /// In en, this message translates to:
  /// **'Mosque locator'**
  String get mosqueTitle;

  /// No description provided for @mosqueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find nearby mosques and directions.'**
  String get mosqueSubtitle;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @librarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tafsir, hadith, and daily remembrance.'**
  String get librarySubtitle;

  /// No description provided for @tafsirTitle.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get tafsirTitle;

  /// No description provided for @hadithTitle.
  ///
  /// In en, this message translates to:
  /// **'Hadith'**
  String get hadithTitle;

  /// No description provided for @azkarTitle.
  ///
  /// In en, this message translates to:
  /// **'Azkar'**
  String get azkarTitle;

  /// No description provided for @azkarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Morning, evening, and after-prayer remembrance.'**
  String get azkarSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personalize language, theme, and reading comfort.'**
  String get settingsSubtitle;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @themeWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get themeWhite;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get themeBlack;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @fontSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Font size'**
  String get fontSizeTitle;

  /// No description provided for @fontWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Font weight'**
  String get fontWeightTitle;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Planned for the next implementation step.'**
  String get comingSoon;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonLoading;

  /// No description provided for @commonOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get commonOff;

  /// No description provided for @backupPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & privacy'**
  String get backupPrivacyTitle;

  /// No description provided for @backupPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypted local backup, restore, merge, and erase controls.'**
  String get backupPrivacySubtitle;

  /// No description provided for @readingJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading journey'**
  String get readingJourneyTitle;

  /// No description provided for @hifzDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Hifz learning'**
  String get hifzDashboardTitle;

  /// No description provided for @prayerJournalTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer & fasting journal'**
  String get prayerJournalTitle;

  /// No description provided for @worshipToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Worship tools'**
  String get worshipToolsTitle;

  /// No description provided for @duasTitle.
  ///
  /// In en, this message translates to:
  /// **'Duas & supplications'**
  String get duasTitle;

  /// No description provided for @divineNamesTitle.
  ///
  /// In en, this message translates to:
  /// **'The 99 Names'**
  String get divineNamesTitle;

  /// No description provided for @zakatTitle.
  ///
  /// In en, this message translates to:
  /// **'Zakat calculator'**
  String get zakatTitle;

  /// No description provided for @ramadanTitle.
  ///
  /// In en, this message translates to:
  /// **'Ramadan dashboard'**
  String get ramadanTitle;

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Private achievements'**
  String get achievementsTitle;

  /// No description provided for @mosquesTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby mosques'**
  String get mosquesTitle;

  /// No description provided for @quranTranslationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran translations'**
  String get quranTranslationsTitle;

  /// No description provided for @translationCompareTitle.
  ///
  /// In en, this message translates to:
  /// **'Compare up to three translations'**
  String get translationCompareTitle;

  /// No description provided for @translationCompareDescription.
  ///
  /// In en, this message translates to:
  /// **'The first selected edition is primary for continuous reading. Verse mode displays every selected downloaded edition.'**
  String get translationCompareDescription;

  /// No description provided for @translationManageAction.
  ///
  /// In en, this message translates to:
  /// **'Manage and compare translations'**
  String get translationManageAction;

  /// No description provided for @translationPrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get translationPrimary;

  /// No description provided for @translationComparison.
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get translationComparison;

  /// No description provided for @translationMakePrimary.
  ///
  /// In en, this message translates to:
  /// **'Make primary'**
  String get translationMakePrimary;

  /// No description provided for @translationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search language, edition, or translator'**
  String get translationSearchHint;

  /// No description provided for @translationSurahPack.
  ///
  /// In en, this message translates to:
  /// **'Surah pack to download'**
  String get translationSurahPack;

  /// No description provided for @translationDownloadSurah.
  ///
  /// In en, this message translates to:
  /// **'Download Surah'**
  String get translationDownloadSurah;

  /// No description provided for @translationGetAll.
  ///
  /// In en, this message translates to:
  /// **'Get all'**
  String get translationGetAll;

  /// No description provided for @translationRefreshAll.
  ///
  /// In en, this message translates to:
  /// **'Refresh all'**
  String get translationRefreshAll;

  /// No description provided for @translationDeletePacks.
  ///
  /// In en, this message translates to:
  /// **'Delete translation packs'**
  String get translationDeletePacks;

  /// No description provided for @translationSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get translationSource;

  /// No description provided for @translationLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get translationLicense;

  /// No description provided for @translationTranslator.
  ///
  /// In en, this message translates to:
  /// **'Translator'**
  String get translationTranslator;

  /// No description provided for @translationPublisherUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Publisher metadata not supplied by provider'**
  String get translationPublisherUnavailable;

  /// No description provided for @translationRevisionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Revision not supplied by provider'**
  String get translationRevisionUnavailable;

  /// No description provided for @translationCacheWindow.
  ///
  /// In en, this message translates to:
  /// **'Downloaded resources have a seven-day cache window.'**
  String get translationCacheWindow;

  /// No description provided for @searchEverythingTitle.
  ///
  /// In en, this message translates to:
  /// **'Search everything'**
  String get searchEverythingTitle;

  /// No description provided for @searchEverythingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find Quran text, surahs, translations, tafsir, notes, hadith, and azkar from local data.'**
  String get searchEverythingSubtitle;

  /// No description provided for @privacyLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Private data stays on this device unless you explicitly export it.'**
  String get privacyLocalOnly;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get noResults;

  /// No description provided for @selectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selectedLabel;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get systemLanguage;

  /// No description provided for @contentLanguagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Content languages'**
  String get contentLanguagesTitle;

  /// No description provided for @contentLanguagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Each content type keeps its own selection.'**
  String get contentLanguagesSubtitle;

  /// No description provided for @settingsPrivacyDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get settingsPrivacyDataTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'ur':
      return AppLocalizationsUr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
