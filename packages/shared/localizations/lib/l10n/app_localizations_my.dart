// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Burmese (`my`).
class AppLocalizationsMy extends AppLocalizations {
  AppLocalizationsMy([String locale = 'my']) : super(locale);

  @override
  String get about => 'ဤအက်ပ်အကြောင်း';

  @override
  String get add => 'ထည့်မည်';

  @override
  String get addEvent => 'Event ထည့်မည်';

  @override
  String get allDay => 'တစ်နေ့လုံး';

  @override
  String get alternativeCalculationMethod => 'အခြားတွက်ချက်နည်း';

  @override
  String get alwaysUseDarkTheme => 'အမှောင် Theme ကို အမြဲသုံးမည်';

  @override
  String get alwaysUseLightTheme => 'အလင်း Theme ကို အမြဲသုံးမည်';

  @override
  String get analytics => 'Analytics';

  @override
  String get analyticsDisabledChangeInSettings =>
      'Analytics ပိတ်ထားပြီးပါပြီ။ Settings တွင် ပြောင်းနိုင်သည်။';

  @override
  String get analyticsDisabledInSettings =>
      'Analytics ပိတ်ထားပြီးပါပြီ။ Settings တွင် ပြန်ဖွင့်နိုင်သည်။';

  @override
  String get analyticsEnabledChangeInSettings =>
      'ကျေးဇူးတင်ပါတယ်! Analytics ဖွင့်ထားပြီးပါပြီ။ Settings တွင် ပြောင်းနိုင်သည်။';

  @override
  String get anniversary_days => 'နှစ်ပတ်လည်နေ့များ';

  @override
  String get appLanguage => 'အက်ပ် ဘာသာစကား';

  @override
  String get apply => 'အသုံးပြုမည်';

  @override
  String get appUpdates => 'အက်ပ် အပ်ဒိတ်များ';

  @override
  String get appVersion => 'အက်ပ် ဗားရှင်း';

  @override
  String get appearance => 'အသွင်အပြင်';

  @override
  String get arithmetic => 'ဂဏန်းသင်္ချာ';

  @override
  String get astrological_information => 'နက္ခတ်ဗေဒဆိုင်ရာအချက်အလက်များ';

  @override
  String get astrology => 'နက္ခတ်ဗေဒင်';

  @override
  String get britishCalendarSystem => 'ဗြိတိသျှ ပြက္ခဒိန်စနစ်';

  @override
  String get buddhist_era => 'ဗုဒ္ဓခေတ် (BE)';

  @override
  String get calculate => 'တွက်ချက်မှု';

  @override
  String get calendar => 'ပြက္ခဒိန်';

  @override
  String get calendarChooseMonth => 'လ ရွေးမည်';

  @override
  String calendarDaysAgo(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString ရက်က';
  }

  @override
  String calendarDaysFromToday(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return 'ယနေ့မှ $daysString ရက်အကြာ';
  }

  @override
  String calendarDaysShort(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString ရက်';
  }

  @override
  String calendarEventCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Event $countString ခု',
    );
    return '$_temp0';
  }

  @override
  String get calendarFullDayDetails => 'နေ့အသေးစိတ် အပြည့်အစုံ';

  @override
  String get calendarFullDayDetailsSubtitle =>
      'ဗေဒင်၊ ဗုဒ္ဓပြက္ခဒိန်၊ AI prompt';

  @override
  String calendarInDays(int days) {
    final intl.NumberFormat daysNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String daysString = daysNumberFormat.format(days);

    return '$daysString ရက်အကြာ';
  }

  @override
  String get calendarJumpToMonth => 'လသို့ သွားမည်';

  @override
  String calendarLabelCopied(String label) {
    return '$label ကူးယူပြီးပါပြီ!';
  }

  @override
  String get calendarLanguage => 'ပြက္ခဒိန် ဘာသာစကား';

  @override
  String calendarMakeYourCalendar(String year) {
    return 'သင့် $year ပြက္ခဒိန်ကို ဖန်တီးမည်';
  }

  @override
  String get calendarNextYear => 'နောက်နှစ်';

  @override
  String get calendarPreviousYear => 'ယခင်နှစ်';

  @override
  String get calendarStudio => 'Calendar Studio';

  @override
  String get calendarToggleDayDetails =>
      'နေ့အသေးစိတ် ပြမည် သို့မဟုတ် ဖျောက်မည်';

  @override
  String get calendarType => 'ပြက္ခဒိန် အမျိုးအစား';

  @override
  String get calendarTypeBritish => 'ဗြိတိသျှ';

  @override
  String get calendarTypeGregorian => 'ဂရီဂေါရီယန်';

  @override
  String get calendarTypeJulian => 'ဂျူလီယန်';

  @override
  String get calendar_configuration => 'ပြက္ခဒိန်ဖွဲ့စည်းမှု';

  @override
  String get calendarUpcoming => 'လာမည့်ရက်များ';

  @override
  String get cancel => 'ပယ်ဖျက်မည်';

  @override
  String get categories => 'အမျိုးအစားများ';

  @override
  String get category => 'အမျိုးအစား';

  @override
  String get checkAgain => 'ထပ်မံစစ်ဆေးမည်';

  @override
  String get checkFailed => 'စစ်ဆေးမှု မအောင်မြင်ပါ';

  @override
  String get checkForNewVersionsAndUpdateSettings =>
      'ဗားရှင်းအသစ်များ စစ်ဆေးပြီး အပ်ဒိတ် ဆက်တင်များကို ကြည့်ရှုပါ';

  @override
  String get checkForUpdates => 'အပ်ဒိတ် စစ်ဆေးမည်';

  @override
  String get choose_your_view => 'သင်၏အမြင်ကိုရွေးချယ်ပါ';

  @override
  String get clear => 'ရှင်းမည်';

  @override
  String get clearPromoDataDebug => 'Promo Data ဖျက်ရန် (Debug)';

  @override
  String get close => 'ပိတ်မည်';

  @override
  String get colour => 'အရောင်';

  @override
  String get comingSoon => 'မကြာမီ ရရှိမည်';

  @override
  String get consentDescription =>
      'Myanmar Calendar သည် သင့်အတွေ့အကြုံကို တိုးတက်ကောင်းမွန်စေရန် analytics နှင့် crash reports များကို စုဆောင်းလိုပါသည်။\n\nဤဒေတာကို တတိယပါတီများနှင့် မမျှဝေပါ။';

  @override
  String get consentDialogDescription =>
      'Myanmar Calendar သည် သင့်အတွေ့အကြုံကို တိုးတက်ကောင်းမွန်စေရန် analytics နှင့် crash reports များကို စုဆောင်းလိုပါသည်။ ဤဒေတာကို တတိယပါတီများနှင့် မမျှဝေပါ။\n\nဤဆက်တင်များကို Settings > Privacy & Data တွင် အချိန်မရွေး ပြောင်းနိုင်ပါသည်။';

  @override
  String get consentSettingsHint =>
      'ဤဆက်တင်များကို Settings > Privacy & Data တွင် အချိန်မရွေး ပြောင်းနိုင်ပါသည်';

  @override
  String get convert => 'ပြောင်းလဲခြင်း';

  @override
  String get converter => 'ပြောင်းလဲခြင်း';

  @override
  String get converterAddSub => 'ပေါင်း/နုတ်';

  @override
  String get converterConvertedDate => 'ပြောင်းလဲထားသော ရက်စွဲ';

  @override
  String get converterDateArithmetic => 'ရက်စွဲ တွက်ချက်ခြင်း';

  @override
  String get converterDateDifference => 'ရက်စွဲ ကွာခြားချက်';

  @override
  String converterDaysUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ရက်',
    );
    return '$_temp0';
  }

  @override
  String get converterDifference => 'ကွာခြားချက်';

  @override
  String get converterEnd => 'ပြီးဆုံးရက်';

  @override
  String get converterEnterMyanmarDate => 'မြန်မာ နှစ်၊ လ နှင့် ရက် ထည့်ပါ။';

  @override
  String get converterEnterWholeNumber => '၀ ထက်ကြီးသော ကိန်းပြည့် ထည့်ပါ။';

  @override
  String get converterFrom => 'မှ';

  @override
  String converterInDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString ရက်အကြာ',
    );
    return '$_temp0';
  }

  @override
  String get converterMonthDayRange =>
      'လသည် ၀–၁၄ ဖြစ်ပြီး ရက်သည် ၁–၃၀ ဖြစ်ရမည်။';

  @override
  String get converterMonthFooter =>
      'လ: ၀ = ပဌမဝါဆို၊ ၁–၁၂ = တန်ခူးမှ တပေါင်း၊ ၁၃ = နှောင်းတန်ခူး၊ ၁၄ = ဒုတိယဝါဆို။';

  @override
  String get converterMoonPhase => 'လအခြေအနေ';

  @override
  String get converterMyanmarDate => 'မြန်မာ ရက်စွဲ';

  @override
  String get converterMyanmarToWestern => 'မြန်မာ → အင်္ဂလိပ်';

  @override
  String converterNextPhase(String name) {
    return 'နောက်လာမည့် $name';
  }

  @override
  String get converterResult => 'ရလဒ်';

  @override
  String get converterStart => 'စတင်ရက်';

  @override
  String get converterStartFromToday => 'ယနေ့မှ စမည်';

  @override
  String get converterSubtract => 'နုတ်မည်';

  @override
  String get converterSwapDates => 'ရက်စွဲများ လဲမည်';

  @override
  String get converterTodayLower => 'ယနေ့';

  @override
  String converterUnit(String unit) {
    String _temp0 = intl.Intl.selectLogic(unit, {
      'days': 'ရက်',
      'weeks': 'ပတ်',
      'months': 'လ',
      'years': 'နှစ်',
      'other': '$unit',
    });
    return '$_temp0';
  }

  @override
  String get converterValue => 'တန်ဖိုး';

  @override
  String get converterWesternToMyanmar => 'အင်္ဂလိပ် → မြန်မာ';

  @override
  String get copied => 'ကူးယူပြီးပါပြီ';

  @override
  String get copy => 'ကူးယူမည်';

  @override
  String get crashReports => 'Crash Reports';

  @override
  String get create => 'ဖန်တီးမည်';

  @override
  String get currentVersion => 'လက်ရှိ ဗားရှင်း';

  @override
  String currentVersionWithBuild(Object version, Object build) {
    return 'လက်ရှိ: $version ($build)';
  }

  @override
  String get custom => 'စိတ်ကြိုက်';

  @override
  String get dark => 'အမှောင်';

  @override
  String get date => 'ရက်စွဲ';

  @override
  String get day => 'နေ့';

  @override
  String get day_view => 'နေ့မြင်ကွင်း';

  @override
  String get dayDetailsAddEvent => 'Event ထည့်မည်';

  @override
  String get dayDetailsAiHoroscopePrompt => 'AI ဟောစာတမ်း Prompt';

  @override
  String get dayDetailsAiHoroscopePromptSubtitle =>
      'ဤနေ့အတွက် အသင့်ရေးထားသော prompt ကို ကူးယူပါ';

  @override
  String get dayDetailsAiPromptHint =>
      'ဤနေ့၏ ဟောစာတမ်းအတွက် AI assistant (ChatGPT, Gemini, …) တစ်ခုခုတွင် ကူးထည့်ပါ။ ဤအက်ပ်မှ မည်သည့်အချက်အလက်မှ မပို့ပါ။';

  @override
  String get dayDetailsBuddhistCalendar => 'ဗုဒ္ဓပြက္ခဒိန်';

  @override
  String get dayDetailsCopyPrompt => 'Prompt ကူးယူမည်';

  @override
  String get dayDetailsErrorLoadingEvents => 'Events များ ဖွင့်၍ မရပါ';

  @override
  String dayDetailsFailedToUpdateEvent(String error) {
    return 'Event ကို ပြင်ဆင်၍ မရပါ: $error';
  }

  @override
  String dayDetailsFortnightDayPercentLit(String day, String percent) {
    return '$day ရက် · $percent% လင်း';
  }

  @override
  String get dayDetailsJumpToDate => 'ရက်စွဲသို့ သွားမည်';

  @override
  String get dayDetailsLoadingEvents => 'Events များ ဖွင့်နေသည်…';

  @override
  String get dayDetailsMarkNotDone => 'မပြီးသေးကြောင်း မှတ်မည်';

  @override
  String get dayDetailsNextDay => 'နောက်နေ့';

  @override
  String get dayDetailsNoEventsAddEvent => 'Event မရှိပါ · Event ထည့်မည်';

  @override
  String dayDetailsPercentLit(String percent) {
    return '$percent% လင်း';
  }

  @override
  String get dayDetailsPreviousDay => 'ယခင်နေ့';

  @override
  String get dayDetailsPromptCopied => 'Prompt ကို ကူးယူပြီးပါပြီ';

  @override
  String get dayDetailsPyathada => 'ပြဿဒါး';

  @override
  String get dayDetailsShareDay => 'နေ့ကို မျှဝေမည်';

  @override
  String get dayDetailsShareFailed => 'မျှဝေ၍ မရပါ';

  @override
  String get dayDetailsShareSubject => 'မြန်မာပြက္ခဒိန်ကို ကြည့်ပေးပါ';

  @override
  String get dayDetailsSpecial => 'ထူးခြားရက်';

  @override
  String get dayDetailsYatyaza => 'ရက်ရာဇာ';

  @override
  String get dayDetailsYearType => 'နှစ်အမျိုးအစား';

  @override
  String get days => 'ရက်';

  @override
  String get defaultCalculationMethod => 'မူလတွက်ချက်နည်း';

  @override
  String get defaultLabel => 'မူလ';

  @override
  String get delete => 'ဖျက်မည်';

  @override
  String get deleteEvent => 'Event ဖျက်မည်';

  @override
  String get deleteEventQuestion => 'Event ကို ဖျက်မလား?';

  @override
  String get description => 'ဖော်ပြချက်';

  @override
  String get developer => 'Kyaw Zayar Tun';

  @override
  String get disableAll => 'အားလုံး ပိတ်မည်';

  @override
  String get displayAnniversaryDaysIndicators =>
      'နှစ်ပတ်လည်နေ့ အမှတ်အသားများ ပြသမည်';

  @override
  String get displayAppInEnglish => 'အက်ပ်ကို အင်္ဂလိပ်ဖြင့် ပြသမည်';

  @override
  String get displayAppInMyanmar => 'အက်ပ်ကို မြန်မာဖြင့် ပြသမည်';

  @override
  String get displayAstrologicalIndicators => 'နက္ခတ်ဗေဒ အမှတ်အသားများ ပြသမည်';

  @override
  String displayCalendarIn(Object language) {
    return 'ပြက္ခဒိန်ကို $language ဖြင့် ပြသမည်';
  }

  @override
  String get displayHolidayIndicators => 'ရုံးပိတ်ရက် အမှတ်အသားများ ပြသမည်';

  @override
  String get displayMyanmarCalendarDates =>
      'မြန်မာ ပြက္ခဒိန် ရက်စွဲများ ပြသမည်';

  @override
  String get displaySabbathIndicators => 'ဥပုသ် အမှတ်အသားများ ပြသမည်';

  @override
  String get displayWesternCalendarDates =>
      'အနောက်တိုင်း ပြက္ခဒိန် ရက်စွဲများ ပြသမည်';

  @override
  String get display_preferences => 'ပြသရန် ဆက်တင်များ';

  @override
  String get edit => 'ပြင်မည်';

  @override
  String get editEvent => 'Event ပြင်မည်';

  @override
  String get enableAll => 'အားလုံး ဖွင့်မည်';

  @override
  String get english => 'အင်္ဂလိပ်';

  @override
  String get errorLoadingSettings => 'ဆက်တင်များ ဖတ်ရာတွင် အမှားဖြစ်ပွား';

  @override
  String get errorTitle => 'အမှား';

  @override
  String errorWithMessage(Object error) {
    return 'အမှား: $error';
  }

  @override
  String get event => 'Event';

  @override
  String get events => 'Events';

  @override
  String get eventsAddReminder => 'သတိပေးချက် ထည့်မည်';

  @override
  String get eventsAddTagHint => 'တဂ်ရိုက်ထည့်ပြီး Return နှိပ်ပါ';

  @override
  String get eventsBuiltInCategoriesFooter =>
      'မူလပါရှိသော အမျိုးအစားများကို ပြောင်း၍မရပါ။';

  @override
  String get eventsCategoryColour => 'အမျိုးအစား အရောင်';

  @override
  String get eventsCompleted => 'ပြီးဆုံးပြီ';

  @override
  String get eventsCouldNotLoadEvent => 'ဤ Event ကို ဖွင့်၍မရပါ';

  @override
  String get eventsCreateEvent => 'Event ဖန်တီးမည်';

  @override
  String get eventsCustomCategoriesEmptyFooter =>
      'သင့် Event များအတွက် အမျိုးအစားများ ဖန်တီးပါ။';

  @override
  String get eventsCustomCategoriesFooter =>
      'အမည်ပြောင်းရန်၊ အရောင်ပြောင်းရန် သို့မဟုတ် ဖျက်ရန် အမျိုးအစားကို နှိပ်ပါ။';

  @override
  String eventsDayEventsSemantics(String date, int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$date၊ Event $countString ခု';
  }

  @override
  String get eventsDeleteCategory => 'အမျိုးအစား ဖျက်မည်';

  @override
  String get eventsDeleteCategoryMessage =>
      '၎င်း၏ Event များ ကျန်ရှိနေမည်ဖြစ်ပြီး ဤအမျိုးအစားနှင့် ချိတ်ဆက်မှုသာ ပျက်သွားပါမည်။';

  @override
  String eventsDeleteCategoryQuestion(String name) {
    return '“$name” ကို ဖျက်မလား?';
  }

  @override
  String get eventsDeleteEventMessage =>
      'ဤ Event ကို ဖယ်ရှားပါမည်။ ပြန်ပြင်၍ မရပါ။';

  @override
  String get eventsDeleteThisOccurrence => 'ဤတစ်ကြိမ်ကို ဖျက်မည်';

  @override
  String get eventsDeleteThisOccurrenceQuestion => 'ဤတစ်ကြိမ်ကို ဖျက်မလား?';

  @override
  String get eventsEditCategory => 'အမျိုးအစား ပြင်ဆင်ရန်';

  @override
  String get eventsEditEventTitle => 'Event ပြင်ဆင်ရန်';

  @override
  String eventsEventCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Event $countString ခု';
  }

  @override
  String get eventsEventCreated => 'Event ဖန်တီးပြီးပါပြီ';

  @override
  String get eventsEventNotFound => 'Event ကို ရှာမတွေ့ပါ';

  @override
  String get eventsEventUpdated => 'Event ပြင်ဆင်ပြီးပါပြီ';

  @override
  String eventsEventWillBeRemoved(String title) {
    return '“$title” ကို ဖယ်ရှားပါမည်။ ပြန်ပြင်၍ မရပါ။';
  }

  @override
  String get eventsFillRequiredFields => 'လိုအပ်သော အကွက်များကို ဖြည့်ပါ';

  @override
  String get eventsJumpToToday => 'ယနေ့သို့ သွားမည်';

  @override
  String get eventsMayHaveBeenDeleted => 'ဖျက်ပြီးဖြစ်နိုင်ပါသည်။';

  @override
  String get eventsNewCategory => 'အမျိုးအစား အသစ်';

  @override
  String eventsNoEventsOn(String date) {
    return '$date တွင် Event မရှိပါ';
  }

  @override
  String get eventsNoResultsFound => 'ရလဒ် မတွေ့ပါ';

  @override
  String get eventsOccurrence => 'ထပ်ခါဖြစ်ရပ်';

  @override
  String get eventsOnlyThisOccurrenceRemoved => 'ဤတစ်ကြိမ်ကိုသာ ဖယ်ရှားပါမည်။';

  @override
  String get eventsPickAColor => 'အရောင် ရွေးပါ';

  @override
  String get eventsPickADate => 'ရက်စွဲ ရွေးမည်';

  @override
  String get eventsPickAnotherDay =>
      'အခြားနေ့ကို ရွေးပါ သို့မဟုတ် အသစ်ဖန်တီးပါ။';

  @override
  String get eventsReminderAtStart => 'စတင်ချိန်တွင်';

  @override
  String eventsReminderDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString ရက်';
  }

  @override
  String eventsReminderHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString နာရီ';
  }

  @override
  String eventsReminderMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString မိနစ်';
  }

  @override
  String get eventsRemoveReminder => 'သတိပေးချက် ဖယ်ရှားမည်';

  @override
  String get eventsReopenEvent => 'Event ကို ပြန်ဖွင့်မည်';

  @override
  String get eventsRepeatsDaily => 'နေ့စဉ် ထပ်သည်';

  @override
  String eventsRepeatsEveryNDays(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString ရက်တစ်ကြိမ် ထပ်သည်';
  }

  @override
  String eventsRepeatsEveryNMonths(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString လတစ်ကြိမ် ထပ်သည်';
  }

  @override
  String eventsRepeatsEveryNWeeks(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString ပတ်တစ်ကြိမ် ထပ်သည်';
  }

  @override
  String eventsRepeatsEveryNYears(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString နှစ်တစ်ကြိမ် ထပ်သည်';
  }

  @override
  String get eventsRepeatsMonthly => 'လစဉ် ထပ်သည်';

  @override
  String get eventsRepeatsWeekly => 'အပတ်စဉ် ထပ်သည်';

  @override
  String get eventsRepeatsYearly => 'နှစ်စဉ် ထပ်သည်';

  @override
  String get eventsResults => 'ရလဒ်များ';

  @override
  String get eventsSaveChanges => 'ပြောင်းလဲမှုများ သိမ်းမည်';

  @override
  String get eventsSaving => 'သိမ်းနေသည်…';

  @override
  String get eventsSearchEvents => 'Event များ ရှာမည်';

  @override
  String get eventsSearchPromptHint =>
      'ခေါင်းစဉ် သို့မဟုတ် ဖော်ပြချက် ရိုက်ထည့်ပါ';

  @override
  String get eventsTryDifferentKeyword => 'အခြားစကားလုံးဖြင့် ရှာကြည့်ပါ';

  @override
  String get failedToFetchHolidayConfig =>
      'ဆာဗာမှ holiday config ကို မရယူနိုင်ပါ။';

  @override
  String failedToInitializeApp(Object error) {
    return 'App ကို စတင်မရပါ:\n\n$error';
  }

  @override
  String get fetchRemoteConfigNowAndCheckAgain =>
      'Remote Config ကို ယခုရယူပြီး ပြန်စစ်မည်';

  @override
  String get forceRefreshHolidayConfigDescription =>
      'Remote Config မှ holiday override များကို force refresh လုပ်ပြီး သက်ရောက်စေမည်';

  @override
  String get forceRefreshUpdateConfig =>
      'Update Config ကို Force Refresh လုပ်မည်';

  @override
  String get general => 'အထွေထွေ';

  @override
  String get goBack => 'နောက်သို့ ပြန်သွားမည်';

  @override
  String get goToHome => 'ပင်မသို့ သွားမည်';

  @override
  String get go_to_today => 'ယနေ့သို့ သွားပါ';

  @override
  String get gregorianCalendarSystem => 'ဂရီဂေါရီယန် ပြက္ခဒိန်စနစ်';

  @override
  String get helpImproveBySharingAnalytics =>
      'အသုံးပြုမှု analytics မျှဝေခြင်းဖြင့် app ကိုတိုးတက်ကောင်းမွန်စေရန် ကူညီပါ';

  @override
  String get helpUsImprove => 'ပိုမိုကောင်းမွန်အောင် ကူညီပါ';

  @override
  String holidayConfigRefreshed(
    Object status,
    Object customCount,
    Object disabledCount,
  ) {
    return 'Holiday config ကို refresh လုပ်ပြီးပါပြီ ($status)။ Custom: $customCount, Disabled: $disabledCount';
  }

  @override
  String get holidayConfigRemote => 'Holiday Config (Remote)';

  @override
  String get holidays => 'ရုံးပိတ်ရက်များ';

  @override
  String get home => 'ပင်မ';

  @override
  String get homeWidgets => 'ပင်မ ဝစ်ဂျက်များ';

  @override
  String get home_screen_widget => 'ပင်မစခရင်ဝစ်ဂျက်';

  @override
  String get hours => 'နာရီ';

  @override
  String hoursValue(Object value) {
    return '$value နာရီ';
  }

  @override
  String get icon => 'အိုင်ကွန်';

  @override
  String get initializationErrorTitle => 'စတင်ခြင်း အမှား';

  @override
  String get julianCalendarSystem => 'ဂျူလီယန် ပြက္ခဒိန်စနစ်';

  @override
  String get language => 'ဘာသာစကား';

  @override
  String lastCheckedAt(Object time) {
    return 'နောက်ဆုံးစစ်ဆေးချိန်: $time';
  }

  @override
  String get later => 'နောက်မှ';

  @override
  String latestVersionWithBuild(Object version, Object build) {
    return 'နောက်ဆုံး: $version ($build)';
  }

  @override
  String get light => 'အလင်း';

  @override
  String get loading => 'လုပ်ဆောင်နေသည်...';

  @override
  String get loadingSettings => 'ဆက်တင်များကို ဖတ်နေသည်...';

  @override
  String get location => 'နေရာ';

  @override
  String get mahabote => 'မဟာဘုတ်';

  @override
  String get markAsPending => 'မပြီးသေးကြောင်း မှတ်မည်';

  @override
  String get markComplete => 'ပြီးဆုံးကြောင်း မှတ်မည်';

  @override
  String get matchSystemTheme => 'စနစ် Theme နှင့် ကိုက်ညီစေမည်';

  @override
  String get month => 'လ';

  @override
  String get months => 'လ';

  @override
  String get moon => 'လ';

  @override
  String get moon_phase => 'လအဆင့်';

  @override
  String get myanmar => 'မြန်မာ';

  @override
  String get myanmarCalendar => 'မြန်မာပြက္ခဒိန်';

  @override
  String get myanmar_era => 'မြန်မာခေတ် (ME)';

  @override
  String get nagahle => 'နဂါးခေါင်း';

  @override
  String get nakhat => 'နက္ခတ်';

  @override
  String get name => 'အမည်';

  @override
  String get never => 'မထပ်ပါ';

  @override
  String get newEvent => 'Event အသစ်';

  @override
  String get next_month => 'နောက်လ';

  @override
  String get nextYear => 'နောက်နှစ်';

  @override
  String get noChanges => 'ပြောင်းလဲမှုမရှိ';

  @override
  String get none => 'မရှိ';

  @override
  String get openSourceLicenses => 'Open Source လိုင်စင်များ';

  @override
  String get openStore => 'Store ဖွင့်မည်';

  @override
  String get others => 'အခြား';

  @override
  String get pageNotFound => 'စာမျက်နှာ မတွေ့ပါ';

  @override
  String get preferShanYear => 'ရှမ်းနှစ်ကို ဦးစားပေးမည်';

  @override
  String get preferShanYearDescription =>
      'ရှမ်းဘာသာတွင် မြန်မာနှစ်အစား ရှမ်းနှစ်ကို ပြသမည်';

  @override
  String get previous_month => 'ယခင်လ';

  @override
  String get previousYear => 'ယခင်နှစ်';

  @override
  String get priority => 'ဦးစားပေးအဆင့်';

  @override
  String get privacyAndData => 'ကိုယ်ရေးကိုယ်တာ နှင့် ဒေတာ';

  @override
  String get privacyDataUsageDescription =>
      'ဤဒေတာကို app တိုးတက်စေရန်သာ အသုံးပြုပြီး တတိယပါတီများနှင့် မမျှဝေပါ။';

  @override
  String get privacyPolicy => 'ကိုယ်ရေးကိုယ်တာ မူဝါဒ';

  @override
  String get privacyPolicyContentHint =>
      'App privacy နှင့် policy အကြောင်းအရာများကို ဤနေရာတွင် ပြသမည်။';

  @override
  String get promoDataClearedRestartApp =>
      'Promo data ဖျက်ပြီးပါပြီ။ Onboarding ပြန်မြင်ရန် app ကို restart လုပ်ပါ။';

  @override
  String get refresh => 'ပြန်လည်ဆန်းသစ်မည်';

  @override
  String get releaseNotes => 'ပြောင်းလဲမှု မှတ်စုများ';

  @override
  String get reminders => 'သတိပေးချက်များ';

  @override
  String get repeat => 'ထပ်ခါထပ်ခါ';

  @override
  String get reset => 'ပြန်သတ်မှတ်မည်';

  @override
  String get resetAllSettings => 'ဆက်တင်အားလုံး ပြန်လည်သတ်မှတ်မည်';

  @override
  String get resetOnboardingAnnouncements =>
      'Onboarding နှင့် ကြေညာချက်များ ပြန်လည်စတင်ရန်';

  @override
  String get resetSettingsConfirmation =>
      'ဆက်တင်အားလုံးကို မူလတန်ဖိုးများသို့ ပြန်ထားမည်။ ဤလုပ်ဆောင်ချက်ကို နောက်ပြန်မဆုတ်နိုင်ပါ။';

  @override
  String get resetSettingsQuestion => 'ဆက်တင်များ ပြန်သတ်မှတ်မလား?';

  @override
  String get retry => 'ပြန်ကြိုးစားမည်';

  @override
  String get sabbath => 'ဥပုသ်';

  @override
  String get sasanaYearType => 'သာသနာနှစ် အမျိုးအစား';

  @override
  String get sasana_year => 'သာသနာနှစ်';

  @override
  String get save => 'သိမ်းမည်';

  @override
  String get select => 'ရွေးမည်';

  @override
  String get sendCrashReportsToHelpFixIssues =>
      'ပြဿနာများ ပြင်ဆင်နိုင်ရန် crash reports ပို့ပါ';

  @override
  String get settings => 'ဆက်တင်များ';

  @override
  String get settingsResetSuccessfully => 'ဆက်တင်များ ပြန်သတ်မှတ်ပြီးပါပြီ';

  @override
  String get share => 'မျှဝေမည်';

  @override
  String get showAnniversaryDays => 'နှစ်ပတ်လည်နေ့များ ပြ';

  @override
  String get showAstrology => 'နက္ခတ်ဗေဒ ပြ';

  @override
  String get showHolidays => 'ရုံးပိတ်ရက်များ ပြ';

  @override
  String get showMyanmarDates => 'မြန်မာ ရက်စွဲ ပြ';

  @override
  String get showSabbath => 'ဥပုသ် ပြ';

  @override
  String get showWesternDates => 'အနောက်တိုင်း ရက်စွဲ ပြ';

  @override
  String get somethingWentWrong => 'တစ်ခုခု မှားယွင်းသွားပါသည်';

  @override
  String get special_days => 'အထူးနေ့များ';

  @override
  String get system => 'စနစ်အတိုင်း';

  @override
  String get tags => 'တဂ်များ';

  @override
  String telegramUserLabel(Object userName) {
    return 'TG: $userName';
  }

  @override
  String get themeMode => 'Theme မုဒ်';

  @override
  String get theme_preset => 'ကြိုတင်သတ်မှတ်ထားသည့် အပြင်အဆင်များ';

  @override
  String get time => 'အချိန်';

  @override
  String get timezoneOffset => 'အချိန်ဇုန် ကွာဟချက်';

  @override
  String get timezoneOffsetExample =>
      'ဥပမာ - မြန်မာစံတော်ချိန် (UTC+6:30) အတွက် 6.5';

  @override
  String get title => 'ခေါင်းစဉ်';

  @override
  String get today => 'ယနေ့';

  @override
  String get tomorrow => 'မနက်ဖြန်';

  @override
  String get tryAgain => 'ထပ်ကြိုးစားမည်';

  @override
  String typeValue(Object value) {
    return 'အမျိုးအစား $value';
  }

  @override
  String get unableToOpenUpdatePage => 'အပ်ဒိတ် စာမျက်နှာကို မဖွင့်နိုင်ပါ။';

  @override
  String get unexpectedError => 'မမျှော်လင့်သော အမှား ဖြစ်ပွားခဲ့သည်';

  @override
  String get unknown => 'မသိရှိ';

  @override
  String get unsupportedPlatform => 'မထောက်ပံ့သော ပလက်ဖောင်း';

  @override
  String get upToDate => 'နောက်ဆုံးဗားရှင်း ဖြစ်သည်';

  @override
  String get update => 'အပ်ဒိတ်';

  @override
  String get updateAvailable => 'အပ်ဒိတ် ရနိုင်သည်';

  @override
  String get updateCheckDisabled => 'အပ်ဒိတ် စစ်ဆေးမှု ပိတ်ထားသည်';

  @override
  String get updateNow => 'ယခု အပ်ဒိတ်လုပ်မည်';

  @override
  String get updateRequired => 'အပ်ဒိတ် လိုအပ်သည်';

  @override
  String get updated => 'အပ်ဒိတ်လုပ်ပြီး';

  @override
  String get useCurrentRemoteConfigValues =>
      'လက်ရှိ remote config တန်ဖိုးများကို သုံးမည်';

  @override
  String versionLabel(Object version) {
    return 'ဗားရှင်း $version';
  }

  @override
  String get viewAllLicenses => 'လိုင်စင်အားလုံးကို ကြည့်ရန်';

  @override
  String get viewPrivacyPolicy => 'ကိုယ်ရေးကိုယ်တာ မူဝါဒကို ကြည့်ရန်';

  @override
  String get views => 'အမြင်များ';

  @override
  String get viewsDayViewSubtitle => 'တစ်ရက်အကြောင်း အားလုံး';

  @override
  String get viewsNextWeek => 'နောက်အပတ်';

  @override
  String get viewsPreviousWeek => 'ယခင်အပတ်';

  @override
  String get viewsThisWeek => 'ယခုအပတ်';

  @override
  String get viewsThisYear => 'ယခုနှစ်';

  @override
  String get viewsViewFullMonth => 'တစ်လလုံး ကြည့်မည်';

  @override
  String get viewsWeekViewSubtitle => 'မြန်မာရက်စွဲနှင့် လအခြေအနေပါ ခုနစ်ရက်';

  @override
  String get viewsYearViewSubtitle => 'ရုံးပိတ်ရက် အရေအတွက်နှင့် ၁၂ လလုံး';

  @override
  String get week => 'ရက်သတ္တပတ်';

  @override
  String get week_view => 'ရက်သတ္တပတ်မြင်ကွင်း';

  @override
  String get weekday => 'အပတ်စဉ်';

  @override
  String weekNumber(int number) {
    final intl.NumberFormat numberNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String numberString = numberNumberFormat.format(number);

    return 'ရက်သတ္တပတ် $numberString';
  }

  @override
  String get weeks => 'ရက်သတ္တပတ်';

  @override
  String get widgetSettings => 'ဝစ်ဂျက် ဆက်တင်များ';

  @override
  String get year => 'နှစ်';

  @override
  String get year_name => 'နှစ်အမည်';

  @override
  String get year_view => 'နှစ်မြင်ကွင်း';

  @override
  String get years => 'နှစ်';

  @override
  String get yesterday => 'မနေ့က';

  @override
  String get settingsAppLanguageFooter => 'မီနူး၊ ခလုတ်နှင့် စာတိုများ။';

  @override
  String get settingsCalendarLanguageFooter =>
      'ရက်စွဲ၊ လနှင့် နေ့အမည်၊ လဆန်း လဆုတ်၊ ရုံးပိတ်ရက်နှင့် လအခြေအနေများကို ဝီဂျက်များ အပါအဝင် အက်ပ်တစ်ခုလုံးတွင် ပြောင်းပေးသည်။';
}
