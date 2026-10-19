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
  String get analytics => 'အသုံးပြုမှု စာရင်းအင်း';

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
  String get calendarStudio => 'ပြက္ခဒိန် စတူဒီယို';

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
  String get crashReports => 'ပျက်ကျမှု အစီရင်ခံစာများ';

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
  String get events => 'ပွဲစဉ်များ';

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
  String get holidayConfigRemote => 'အားလပ်ရက် ဆက်တင် (Remote)';

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

  @override
  String get settingsCalendarGrid => 'ပြက္ခဒိန်ဇယား';

  @override
  String get settingsGridLayoutTab => 'အပြင်အဆင်';

  @override
  String get settingsGridThemeTab => 'အရောင်အသွေး';

  @override
  String get settingsGridFitNote =>
      'ပုံစံတိုင်း မျက်နှာပြင်နှင့် အံကိုက်ဖြစ်သည်။ အတန်းများသည် နေ့စာရွက်အပေါ်ရှိ ကျန်နေရာကို ယူသည်။';

  @override
  String get settingsGridThemeFooter =>
      'အရောင်အသွေးသည် လခေါင်းစဉ်၊ နေ့အမည်တန်းနှင့် ဇယားကို အရောင်ခြယ်ပြီး အပြင်အဆင်တိုင်းနှင့် အသုံးပြုနိုင်သည်။ နေ့စာရွက်သည် အက်ပ်အရောင်ကို ဆက်သုံးသည်။';

  @override
  String get settingsGridShowMotif => 'အလှဆင်ပုံ ပြရန်';

  @override
  String get gridAuspiceGood => 'ရက်ကောင်း';

  @override
  String get gridAuspiceCareful => 'သတိ';

  @override
  String get gridLayoutAlmanacTitle => 'ပြက္ခဒိန်စုံ';

  @override
  String get gridLayoutAlmanacDescription =>
      'လရက်၊ လဝန်း၊ ရုံးပိတ်ရက်နှင့် ပွဲများ၊ ဥပုသ်နှင့် ရက်ကောင်း၊ သတိထားရန်ရက်ကို အရောင်တန်းဖြင့် ပြသည်။';

  @override
  String get gridLayoutMonthRegionsTitle => 'မြန်မာလများ';

  @override
  String get gridLayoutMonthRegionsDescription =>
      'မြန်မာလတစ်လစီကို အရောင်ဖြင့် ခွဲပြပြီး လစသည့်နေရာတွင် လအမည်ပြသည်။';

  @override
  String get gridLayoutFocusWeekTitle => 'ရွေးထားသောအပတ်';

  @override
  String get gridLayoutFocusWeekDescription =>
      'ရွေးထားသောအပတ်အောက်တွင် ထိုနေ့၏ အသေးစိတ်ကို ဖွင့်ပြသည်။';

  @override
  String get gridLayoutAuspiceTitle => 'ရက်ကောင်းရက်ဆိုး';

  @override
  String get gridLayoutAuspiceDescription =>
      'ရက်ရာဇာ၊ ပြဿဒါးနှင့် အခြားဗေဒင်ရက်များအလိုက် နေ့များကို အရောင်ခွဲပြသည်။';

  @override
  String get gridLayoutMoonBandTitle => 'လဝန်းတန်း';

  @override
  String get gridLayoutMoonBandDescription =>
      'အပတ်တိုင်းအောက်တွင် လဝန်းအလင်းကို အရောင်တန်းဖြင့် ပြပြီး လပြည့်တွင် အလင်းဆုံး။';

  @override
  String get gridLayoutHeroTodayTitle => 'ယနေ့ကတ်';

  @override
  String get gridLayoutHeroTodayDescription =>
      'ရွေးထားသောနေ့ကို ကတ်ကြီးဖြင့် လ၏အောက်တွင် ပြသည်။';

  @override
  String get gridLayoutWeekRibbonsTitle => 'အပတ်ကတ်များ';

  @override
  String get gridLayoutWeekRibbonsDescription =>
      'အပတ်တစ်ပတ်စီကို ကတ်တစ်ခုဖြင့် ပြပြီး ပွဲများကို နေ့အောက်တွင် အတန်းဖြင့် ပြသည်။';

  @override
  String get gridLayoutDetailedTitle => 'အသေးစိတ်';

  @override
  String get gridLayoutDetailedDescription =>
      'နေ့တိုင်းတွင် လရက်၊ ရုံးပိတ်ရက်အမည်၊ လဝန်းနှင့် ပွဲများ။';

  @override
  String get gridLayoutCleanTitle => 'ရှင်းလင်း';

  @override
  String get gridLayoutCleanDescription =>
      'ရက်စွဲကို ဦးစားပေး၍ လပြည့်၊ လကွယ်နေ့တွင်သာ လဝန်းပြသည်။';

  @override
  String get gridLayoutClassicTitle => 'ဂန္ထဝင်';

  @override
  String get gridLayoutClassicDescription =>
      'မူလ အကွက်များနှင့် အရောင်စက်များ။';

  @override
  String get gridLayoutDetailedV2Title => 'အသေးစိတ် ၂';

  @override
  String get gridLayoutDetailedV2Description =>
      'အသေးစိတ်ကို ပိုငြိမ်စေသည်။ မျဉ်းမပါ၊ လပြည့်၊ လကွယ်နေ့တွင်သာ လဝန်းပြသည်။';

  @override
  String get gridLayoutLunarFirstTitle => 'လရက် ဦးစား';

  @override
  String get gridLayoutLunarFirstDescription =>
      'လရက်ကို ကြီးကြီး၊ ရက်စွဲကို ထောင့်တွင် သေးသေး ပြသည်။';

  @override
  String get gridLayoutMinimalTitle => 'အနည်းဆုံး';

  @override
  String get gridLayoutMinimalDescription => 'ရက်စွဲနှင့် အခြေအနေပြ စက်တစ်ခု။';

  @override
  String get gridLayoutMoonStripTitle => 'လဝန်းတန်း';

  @override
  String get gridLayoutMoonStripDescription => 'နေ့တိုင်းတွင် ထိုညရဲ့ လဝန်း။';

  @override
  String get gridLayoutAgendaTitle => 'အစီအစဉ်';

  @override
  String get gridLayoutAgendaDescription =>
      'ပွဲအမည်များနှင့် ရုံးပိတ်ရက်များကို ရက်ကွက်ထဲတွင် ပြသည်။';

  @override
  String get gridLayoutClassicPrintTitle => 'နံရံပြက္ခဒိန်';

  @override
  String get gridLayoutClassicPrintDescription =>
      'နံရံကပ်ပြက္ခဒိန်ကဲ့သို့ မျဉ်းကြောင်းဇယား။';

  @override
  String get gridLayoutTilesTitle => 'အကွက်များ';

  @override
  String get gridLayoutTilesDescription =>
      'နေ့တိုင်း ကတ်တစ်ခု၊ ရုံးပိတ်ရက်နှင့် ဥပုသ်နေ့ကို အရောင်ခြယ်ထားသည်။';

  @override
  String get gridLayoutMoonlightTitle => 'လရောင်';

  @override
  String get gridLayoutMoonlightDescription =>
      'လပြည့်နီးလေ ရက်ကွက်များ ပိုလင်းလေ။';

  @override
  String get gridLayoutSplitTitle => 'ထောင့်ဖြတ်';

  @override
  String get gridLayoutSplitDescription =>
      'ရက်စွဲနှင့် လရက်ကို ထောင့်ဖြတ်မျဉ်းဖြင့် ခွဲပြသည်။';

  @override
  String get gridLayoutPosterTitle => 'ပိုစတာ';

  @override
  String get gridLayoutPosterDescription =>
      'အဝေးမှ ဖတ်နိုင်သော ကြီးမားထင်ရှားသည့် ဂဏန်းများ။';

  @override
  String get gridLayoutMoonRingTitle => 'လဝန်းကွင်း';

  @override
  String get gridLayoutMoonRingDescription =>
      'ရက်စွဲတိုင်းကို ဝိုင်းထားသော ကွင်းသည် လရောင်ဖြင့် ပြည့်လာသည်။';

  @override
  String get gridLayoutAstrologyTitle => 'ဗေဒင်';

  @override
  String get gridLayoutAstrologyDescription =>
      'ဗေဒင်ရက်များနှင့် ရုံးပိတ်ရက်များကို တံဆိပ်များဖြင့် ပြသည်။';

  @override
  String get gridThemeAppTitle => 'အက်ပ်အရောင်';

  @override
  String get gridThemeAppDescription => 'အက်ပ်၏ မူလအရောင်များ။';

  @override
  String get gridThemePagodaTitle => 'စေတီ';

  @override
  String get gridThemePagodaDescription =>
      'ဘုရားကျောင်း နို့နှစ်ရောင်၊ ရွှေနီရောင်နှင့် စေတီရွှေရောင်။';

  @override
  String get gridThemeJadeTitle => 'ကျောက်စိမ်း';

  @override
  String get gridThemeJadeDescription =>
      'အဖြူရောင်ပေါ်ရှိ ကျောက်စိမ်းရောင်နှင့် တံဆိပ်တုံး။';

  @override
  String get gridThemeLacquerTitle => 'ယွန်းထည်';

  @override
  String get gridThemeLacquerDescription =>
      'ယွန်းအနက်၊ ဟင်္သပဒါးနီနှင့် ရွှေဆိုင်း။';

  @override
  String get gridThemeThadingyutTitle => 'သီတင်းကျွတ်';

  @override
  String get gridThemeThadingyutDescription =>
      'နေ့တွင် မီးပုံးစက္ကူရောင်၊ ညတွင် မဲနယ်ပြာရောင်။';

  @override
  String get gridThemeThingyanTitle => 'သင်္ကြန်';

  @override
  String get gridThemeThingyanDescription =>
      'ရေပက်ပြာရောင်နှင့် ပိတောက်ဝါရောင်။';

  @override
  String get gridThemeBotanicalTitle => 'သစ်ပင်ပန်းမန်';

  @override
  String get gridThemeBotanicalDescription =>
      'စက္ကူပေါ်ရှိ ခြောက်သွေ့သစ်ရွက် စိမ်းရောင်များ။';

  @override
  String get gridThemeMonsoonTitle => 'မိုးရာသီ';

  @override
  String get gridThemeMonsoonDescription =>
      'မိုးရာသီ မီးခိုးပြာရောင်နှင့် သံချေးရောင်။';

  @override
  String get gridThemeTidewaterTitle => 'ဒီရေ';

  @override
  String get gridThemeTidewaterDescription =>
      'ပင်လယ်ဖန်ရောင်နှင့် စိမ်းပြာရင့်ရောင်။';

  @override
  String get gridThemeMorningPourTitle => 'မနက်ခင်း ကော်ဖီ';

  @override
  String get gridThemeMorningPourDescription =>
      'စောစောထသူများအတွက် ကော်ဖီနှင့် နို့ရောင်။';

  @override
  String get gridThemeDeepFieldTitle => 'ကြယ်စုံည';

  @override
  String get gridThemeDeepFieldDescription =>
      'ညနေခင်း ခရမ်းနုရောင်၊ ညတွင် အာကာသနက်ရောင်။';

  @override
  String get gridThemeMoonlightTitle => 'လရောင်';

  @override
  String get gridThemeMoonlightDescription => 'ငွေပြာရောင်နှင့် လရွှေရောင်။';

  @override
  String get gridThemeNightChartTitle => 'ညဇာတာ';

  @override
  String get gridThemeNightChartDescription =>
      'ခရမ်းရောင်မင်နှင့် ရှေးရွှေရောင်။';

  @override
  String settingsGridDefault(String description) {
    return 'မူလ · $description';
  }

  @override
  String get settingsCalendarStudioValue => 'ဒီဇိုင်းဆွဲ၍ ပုံနှိပ်ရန်';

  @override
  String get settingsShowInCalendar => 'ပြက္ခဒိန်တွင် ပြရန်';

  @override
  String get settingsDates => 'ရက်စွဲများ';

  @override
  String get settingsUseDeviceTimezone => 'စက်၏ အချိန်ဇုန်ကို သုံးရန်';

  @override
  String get settingsRefreshHolidayData => 'အားလပ်ရက် ဒေတာ ပြန်ယူရန်';

  @override
  String get settingsDebugBuildsOnly => 'Debug build များတွင်သာ။';

  @override
  String get settingsCustomColours => 'စိတ်ကြိုက် အရောင်များ…';

  @override
  String settingsThemePresetDefault(String name) {
    return '$name (မူလ)';
  }

  @override
  String get settingsAppStyle => 'အက်ပ် ပုံစံ';

  @override
  String get settingsAppStyleAutomatic => 'အလိုအလျောက်';

  @override
  String get settingsAppStyleClear => 'Clear';

  @override
  String get settingsAppStyleMaterial => 'Material';

  @override
  String settingsAppStyleFooter(String style) {
    return 'အလိုအလျောက်သည် Android တွင် Material ကို၊ iPhone၊ iPad၊ Mac နှင့် web တွင် Clear ကို သုံးသည် (ဤနေရာတွင်: $style)။ အရောင်နှင့် အကြောင်းအရာ မပြောင်းဘဲ ဘား၊ စာရင်းနှင့် ခလုတ်များသာ ပြောင်းသည်။';
  }

  @override
  String get settingsAppIcon => 'အက်ပ် အိုင်ကွန်';

  @override
  String get settingsChooseAppIcon => 'အက်ပ် အိုင်ကွန် ရွေးရန်';

  @override
  String get settingsChooseAppIconSubtitle =>
      'နှစ်သက်ရာ launcher အိုင်ကွန် ပုံစံကို ရွေးပါ။';

  @override
  String get settingsAppIconApplying =>
      'ခဏစောင့်ပါ၊ အက်ပ် အိုင်ကွန် ပြောင်းနေသည်...';

  @override
  String get settingsAppIconUnsupported =>
      'ဤနေရာတွင် အက်ပ် အိုင်ကွန် ပြောင်း၍ မရပါ။';

  @override
  String get settingsAppIconFailed => 'အက်ပ် အိုင်ကွန် ပြောင်း၍ မရပါ။';

  @override
  String get settingsAppIconUpdated => 'အက်ပ် အိုင်ကွန် ပြောင်းပြီးပါပြီ။';

  @override
  String get settingsAppIconCurrent => 'လက်ရှိ အိုင်ကွန်';

  @override
  String get settingsAppIconTapApply =>
      'ဤအိုင်ကွန်ကို သုံးရန် အသုံးပြုမည် ကိုနှိပ်ပါ';

  @override
  String get settingsAppIconActive => 'သုံးနေသည်';

  @override
  String get settingsAppIconCurrentShort => 'လက်ရှိ';

  @override
  String get settingsAppIconStandard => 'ပုံမှန် အိုင်ကွန်';

  @override
  String get settingsAppIconAlternate => 'အစားထိုး အိုင်ကွန်';

  @override
  String get appIconMoon => 'လ';

  @override
  String get appIconForest => 'တောအုပ်';

  @override
  String get appIconMinimalFlat => 'ရိုးရှင်း';

  @override
  String get appIconPremiumDark => 'အမှောင် ပရီမီယံ';

  @override
  String get appIconTraditionalMyanmar => 'မြန်မာ ရိုးရာ ပန်းချီ';

  @override
  String get languageZawgyi => 'ဇော်ဂျီ';

  @override
  String get languageMon => 'မွန်';

  @override
  String get languageShan => 'ရှမ်း';

  @override
  String get languageKaren => 'ကရင်';

  @override
  String get customColorsTitle => 'ကိုယ်ပိုင်အရောင်များ';

  @override
  String get customColorsAccent => 'အဓိကအရောင်';

  @override
  String get customColorsAccentFooter =>
      'အခြားအရောင်များကို ဤအရောင်မှ အလင်းနှင့် အမှောင် နှစ်မျိုးလုံးအတွက် ဖန်တီးပေးသည်။';

  @override
  String get customColorsMore => 'နောက်ထပ်အရောင်များ…';

  @override
  String get customColorsPreview => 'အစမ်းကြည့်ရန်';

  @override
  String get customColorsAdvanced => 'အဆင့်မြင့်';

  @override
  String get customColorsAdvancedFooter =>
      'အရောင်တစ်ခုချင်းကို ကိုယ်တိုင် သတ်မှတ်နိုင်သည်။ အဓိကအရောင် ပြောင်းလျှင် ဤအရောင်များ ပြန်ရှင်းသွားမည်။';

  @override
  String get customColorsReset => 'မူလပုံစံသို့ ပြန်ထားမည်';

  @override
  String customColorsResetMessage(String preset) {
    return 'ကိုယ်ပိုင်အရောင်များကို ဖယ်ရှားပြီး $preset ကို ပြန်သုံးမည်။';
  }

  @override
  String get customColorsPickTitle => 'အရောင်ရွေးရန်';

  @override
  String get customColorPrimary => 'အဓိက';

  @override
  String get customColorOnPrimary => 'အဓိကပေါ်ရှိ စာ';

  @override
  String get customColorSecondary => 'ဒုတိယ';

  @override
  String get customColorOnSecondary => 'ဒုတိယပေါ်ရှိ စာ';

  @override
  String get customColorTertiary => 'တတိယ';

  @override
  String get customColorOnTertiary => 'တတိယပေါ်ရှိ စာ';

  @override
  String get customColorError => 'အမှား';

  @override
  String get customColorOnError => 'အမှားပေါ်ရှိ စာ';

  @override
  String get customColorSurface => 'နောက်ခံ';

  @override
  String get customColorOnSurface => 'နောက်ခံပေါ်ရှိ စာ';

  @override
  String get done => 'ပြီးပြီ';

  @override
  String get widgetsStyle => 'ပုံစံ';

  @override
  String get widgetsStyleFooter =>
      'ဝစ်ဂျက်အသစ်များသည် ဤပုံစံဖြင့် စတင်မည်။ ဝစ်ဂျက်တစ်ခုကိုသာ ပြောင်းလိုလျှင် ၎င်းကို ဖိထားပြီး Edit Widget (iPhone) သို့မဟုတ် Reconfigure (Android) ကို ရွေးပါ။';

  @override
  String get widgetStyleApp => 'အက်ပ်အတိုင်း';

  @override
  String get widgetStyleAppDescription =>
      'အက်ပ်၏ အရောင်များ၊ စနစ်အလိုက် အလင်း သို့မဟုတ် အမှောင်။';

  @override
  String get widgetStylePlain => 'ရိုးရိုး';

  @override
  String get widgetStylePlainDescription => 'အဖြူအမည်း၊ ပိတ်ရက်များ အနီရောင်။';

  @override
  String get widgetsShow => 'ဝစ်ဂျက်တွင် ပြရန်';

  @override
  String get widgetsCountdown => 'ရေတွက်မည့်နေ့';

  @override
  String get widgetCountdownFullMoon => 'နောက်လပြည့်';

  @override
  String get widgetCountdownNewMoon => 'နောက်လကွယ်';

  @override
  String get widgetCountdownSabbath => 'နောက်ဥပုသ်';

  @override
  String get widgetCountdownThingyan => 'သင်္ကြန်';

  @override
  String get widgetsOnScreen => 'ပင်မစာမျက်နှာပေါ်တွင်';

  @override
  String widgetsInstalled(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ဝစ်ဂျက် $count ခု',
      zero: 'မရှိသေးပါ',
    );
    return '$_temp0';
  }

  @override
  String get widgetsInstalledTitle => 'ထည့်ထားသော ဝစ်ဂျက်';

  @override
  String get widgetsRefresh => 'ဝစ်ဂျက်များ ပြန်ဆွဲရန်';

  @override
  String get widgetsRefreshed => 'ဝစ်ဂျက်များ ပြန်ဆွဲပြီးပါပြီ';

  @override
  String get widgetsHowToAdd => 'ဝစ်ဂျက် ထည့်နည်း';

  @override
  String get widgetsHowToAddIos =>
      'ပင်မစာမျက်နှာ၏ နေရာလွတ်ကို ဖိထားပြီး Edit၊ ထို့နောက် Add Widget ကို နှိပ်ကာ Myanmar Calendar ကို ရှာပါ။ Lock Screen အတွက် ၎င်းကို ဖိထားပြီး Customize ကို နှိပ်ပါ။';

  @override
  String get widgetsHowToAddAndroid =>
      'ပင်မစာမျက်နှာ၏ နေရာလွတ်ကို ဖိထားပြီး Widgets ကို နှိပ်ကာ Myanmar Calendar ကို ရှာပါ။ အရွယ်အစားပြောင်းရန် ဝစ်ဂျက်ကို ဆွဲပါ။';

  @override
  String widgetsLanguageNote(String language) {
    return 'ဝစ်ဂျက်များသည် ပြက္ခဒိန်ဘာသာစကား ($language) ကို သုံးသည်။';
  }

  @override
  String get widgetsAddToHome => 'ပင်မစာမျက်နှာသို့ ထည့်ရန်';

  @override
  String get widgetsAddToHomeFooter =>
      'မည်သည့်နေရာတွင် ထားမည်ကို launcher က မေးပါမည်။ ထိုနေရာတွင် အရွယ်အစား ပြောင်းနိုင်သည်။';

  @override
  String get widgetKindToday => 'ယနေ့';

  @override
  String get widgetKindMoon => 'လ';

  @override
  String get widgetKindMonth => 'လ ပြက္ခဒိန်';

  @override
  String get widgetKindWeek => 'ရက်သတ္တပတ်';

  @override
  String get widgetKindComingUp => 'လာမည့်နေ့များ';

  @override
  String get widgetKindAgenda => 'ပွဲစဉ်များ';

  @override
  String get widgetKindCountdown => 'ရက်ရေတွက်';

  @override
  String get widgetKindAstrology => 'ရက်ကောင်း ရက်ဆိုး';

  @override
  String get widgetKindYear => 'မြန်မာနှစ်';

  @override
  String get holidayNameNewYear => 'နှစ်သစ်ကူးနေ့';

  @override
  String get holidayAboutNewYear =>
      'ခရစ်နှစ်သစ်၏ ပထမဆုံးနေ့ ဖြစ်ပြီး ၂၀၁၈ ခုနှစ်မှစ၍ ရုံးပိတ်ရက် ဖြစ်သည်။';

  @override
  String get holidayNameIndependence => 'လွတ်လပ်ရေးနေ့';

  @override
  String get holidayAboutIndependence =>
      '၁၉၄၈ ခုနှစ် ဇန်နဝါရီ ၄ ရက်တွင် ဗြိတိသျှ ကိုလိုနီ အုပ်ချုပ်မှုမှ လွတ်လပ်ရေး ရရှိခဲ့ခြင်းကို အထိမ်းအမှတ်ပြုသည်။ နိုင်ငံအနှံ့ အလံလွှင့်ထူကာ ပွဲတော်များ၊ အားကစားပြိုင်ပွဲများ ကျင်းပကြသည်။';

  @override
  String get holidayNameUnion => 'ပြည်ထောင်စုနေ့';

  @override
  String get holidayAboutUnion =>
      '၁၉၄၇ ခုနှစ် ဖေဖော်ဝါရီ ၁၂ ရက်တွင် ဗမာ၊ ရှမ်း၊ ကချင်၊ ချင်း ခေါင်းဆောင်များ ပြည်ထောင်စု ထူထောင်ရန် သဘောတူခဲ့သည့် ပင်လုံစာချုပ်ကို အောက်မေ့သည်။';

  @override
  String get holidayNamePeasants => 'တောင်သူလယ်သမားနေ့';

  @override
  String get holidayAboutPeasants =>
      'နိုင်ငံ၏ စားနပ်ရိက္ခာကို စိုက်ပျိုးထုတ်လုပ်ပေးသော တောင်သူလယ်သမားများကို ဂုဏ်ပြုသည့်နေ့ ဖြစ်ပြီး မတ်လ ၂ ရက်နေ့တွင် ကျရောက်သည်။';

  @override
  String get holidayNameResistance => 'တော်လှန်ရေးနေ့';

  @override
  String get holidayAboutResistance =>
      '၁၉၄၅ ခုနှစ် မတ်လ ၂၇ ရက်တွင် စတင်ခဲ့သော ဂျပန်ဖက်ဆစ် တော်လှန်ရေးကို အောက်မေ့သည့်နေ့ ဖြစ်သည်။ တပ်မတော်နေ့ ဟုလည်း ခေါ်သည်။';

  @override
  String get holidayNameLabour => 'အလုပ်သမားနေ့';

  @override
  String get holidayAboutLabour =>
      'မေလ ၁ ရက်နေ့တွင် ကျရောက်သော အပြည်ပြည်ဆိုင်ရာ အလုပ်သမားနေ့ ဖြစ်ပြီး လုပ်သားပြည်သူများကို ဂုဏ်ပြုသည်။';

  @override
  String get holidayNameMartyrs => 'အာဇာနည်နေ့';

  @override
  String get holidayAboutMartyrs =>
      '၁၉၄၇ ခုနှစ် ဇူလိုင် ၁၉ ရက်တွင် လုပ်ကြံခံခဲ့ရသော ဗိုလ်ချုပ်အောင်ဆန်းနှင့် အစိုးရအဖွဲ့ဝင်များကို အောက်မေ့သည်။ နံနက် ၁၀ နာရီ ၃၇ မိနစ်တွင် ဥဩဆွဲ၍ ငြိမ်သက်စွာ ဂါရဝပြုကြသည်။';

  @override
  String get holidayNameNationalDay => 'အမျိုးသားနေ့';

  @override
  String get holidayAboutNationalDay =>
      'ကိုလိုနီ ပညာရေးဥပဒေကို ဆန့်ကျင်ခဲ့သော ၁၉၂၀ ပြည့်နှစ် ပထမ ကျောင်းသားသပိတ်ကို အောက်မေ့သည့်နေ့ ဖြစ်သည်။ တန်ဆောင်မုန်း လဆုတ် ၁၀ ရက်နေ့တွင် ကျရောက်သည်။';

  @override
  String get holidayNameNewYearsEve => 'နှစ်ကုန်ရက်';

  @override
  String get holidayAboutNewYearsEve =>
      'ခရစ်နှစ်၏ နောက်ဆုံးနေ့ ဖြစ်ပြီး ၂၀၁၈ ခုနှစ်မှစ၍ ရုံးပိတ်ရက် ဖြစ်သည်။';

  @override
  String get holidayNamePublicHoliday => 'ရုံးပိတ်ရက်';

  @override
  String get holidayAboutPublicHoliday =>
      'အစိုးရက ထပ်မံ ကြေညာသော ရုံးပိတ်ရက် ဖြစ်ပြီး စနေ၊ တနင်္ဂနွေနှင့် တိုက်ဆိုင်သော ရုံးပိတ်ရက်အစား ပေးလေ့ရှိသည်။';

  @override
  String get holidayNameTabaung => 'တပေါင်းလပြည့်နေ့';

  @override
  String get holidayAboutTabaung =>
      'မြန်မာနှစ်၏ နောက်ဆုံးလ ဖြစ်သော တပေါင်းလ၏ လပြည့်နေ့ ဖြစ်သည်။ နိုင်ငံအနှံ့ ဘုရားပွဲတော်များ ကျင်းပကြပြီး ရွှေတိဂုံဘုရားပွဲသည် အထင်ရှားဆုံး ဖြစ်သည်။';

  @override
  String get holidayNameBuddhaDay => 'ကဆုန်လပြည့် ဗုဒ္ဓနေ့';

  @override
  String get holidayAboutBuddhaDay =>
      'ကဆုန်လပြည့်နေ့သည် မြတ်စွာဘုရား ဖွားမြင်တော်မူခြင်း၊ ဘုရားဖြစ်တော်မူခြင်းနှင့် ပရိနိဗ္ဗာန်စံဝင်တော်မူခြင်းကို အထိမ်းအမှတ်ပြုသည်။ ဘုရားများရှိ ဗောဓိညောင်ပင်များကို ရေသွန်းလောင်းကြသည်။';

  @override
  String get holidayNameLentStart => 'ဝါဆိုလပြည့် ဓမ္မစကြာနေ့';

  @override
  String get holidayAboutLentStart =>
      'ဝါဆိုလပြည့်နေ့တွင် သုံးလကြာ ဝါတွင်းကာလ စတင်သည်။ ရဟန်းတော်များ ကျောင်းတွင် ဝါကပ်ကြပြီး လူအများ သီလ ပိုမို စောင့်ထိန်းကြသည်။';

  @override
  String get holidayNameThadingyut => 'သီတင်းကျွတ် မီးထွန်းပွဲ';

  @override
  String get holidayAboutThadingyut =>
      'သီတင်းကျွတ်လပြည့်နေ့တွင် သုံးလကြာ ဝါတွင်းကာလ ကုန်ဆုံးသည်။ အိမ်များနှင့် ဘုရားများကို သုံးညတိုင်တိုင် ဆီမီး၊ မီးအိမ်များ ထွန်းညှိကြပြီး လူငယ်များက မိဘ၊ ဆရာသမားနှင့် သက်ကြီးဝါကြီးများကို ကန်တော့ကြသည်။';

  @override
  String get holidayNameTazaungdaing => 'တန်ဆောင်တိုင်';

  @override
  String get holidayAboutTazaungdaing =>
      'တန်ဆောင်မုန်းလပြည့်နေ့သည် ကထိန်ကာလ ပြီးဆုံးရာ မီးထွန်းပွဲတော် ဖြစ်သည်။ တောင်ကြီးတွင် မီးပုံးပျံပွဲ ကျင်းပပြီး ညလုံးပေါက် မသိုးသင်္ကန်း ရက်လုပ်ပြိုင်ပွဲများ ကျင်းပကြသည်။';

  @override
  String get holidayNameChristmas => 'ခရစ္စမတ်';

  @override
  String get holidayAboutChristmas =>
      'ခရစ်ယာန်များက ဒီဇင်ဘာ ၂၅ ရက်နေ့တွင် ယေရှုခရစ် မွေးဖွားခြင်းကို ကျင်းပကြသည်။';

  @override
  String get holidayNameDiwali => 'ဒီဝါလီ';

  @override
  String get holidayAboutDiwali =>
      'ဟိန္ဒူဘာသာဝင်တို့၏ မီးထွန်းပွဲတော် ဖြစ်ပြီး ဆီမီးများ ထွန်းညှိကာ မုန့်များ ဝေငှ၍ ဆုတောင်းကြသည်။';

  @override
  String get holidayNameEidAlAdha => 'အိဒ်နေ့ (Eid al-Adha)';

  @override
  String get holidayAboutEidAlAdha =>
      'ဟဂ်ျခရီး ပြီးဆုံးချိန်တွင် ကျင်းပသော မွတ်စလင်တို့၏ ပူဇော်ပွဲ ဖြစ်သည်။ ရက်စွဲသည် အစ္စလာမ် ပြက္ခဒိန်အတိုင်း ပြောင်းလဲသည်။';

  @override
  String get holidayNameGoodFriday => 'သောကြာနေ့ကြီး';

  @override
  String get holidayAboutGoodFriday =>
      'ထမြောက်ရာနေ့ မတိုင်မီ သောကြာနေ့တွင် ယေရှုခရစ် လက်ဝါးကပ်တိုင်ပေါ်တွင် အသေခံခြင်းကို ခရစ်ယာန်များ အောက်မေ့ကြသည်။';

  @override
  String get holidayNameEaster => 'ထမြောက်ရာနေ့';

  @override
  String get holidayAboutEaster =>
      'ယေရှုခရစ် ရှင်ပြန်ထမြောက်ခြင်းကို ခရစ်ယာန်များ ကျင်းပကြသည်။';

  @override
  String get holidayNameEidAlFitr => 'အိဒ်နေ့ (Eid al-Fitr)';

  @override
  String get holidayAboutEidAlFitr =>
      'ရမ်ဇာန် ဥပုသ်လ ကုန်ဆုံးချိန်တွင် ကျင်းပသော မွတ်စလင်တို့၏ ပွဲတော် ဖြစ်သည်။ ရက်စွဲသည် အစ္စလာမ် ပြက္ခဒိန်အတိုင်း ပြောင်းလဲသည်။';

  @override
  String get holidayNameMahathamaya => 'မဟာသမယနေ့';

  @override
  String get holidayAboutMahathamaya =>
      'နယုန်လပြည့်နေ့တွင် မြတ်စွာဘုရား နတ်ဗြဟ္မာ အစည်းအဝေးကြီးအား မဟာသမယသုတ်ကို ဟောကြားတော်မူခဲ့ခြင်းကို အောက်မေ့သည်။';

  @override
  String get holidayNameGarudhamma => 'ဂရုဓမ္မနေ့';

  @override
  String get holidayAboutGarudhamma =>
      'တော်သလင်းလပြည့်နေ့တွင် မြတ်စွာဘုရား ပထမဆုံး ဘိက္ခုနီများအား ဂရုဓမ္မ ရှစ်ပါးကို ပေးတော်မူခဲ့ခြင်းကို အောက်မေ့သည်။';

  @override
  String get holidayNameMetta => 'မေတ္တာနေ့';

  @override
  String get holidayAboutMetta =>
      'ဝါခေါင်လပြည့်နေ့ ဖြစ်ပြီး မေတ္တာ ပွားများရန် အထူးသတ်မှတ်ထားသောနေ့ ဖြစ်သည်။';

  @override
  String get holidayNameThingyan => 'သင်္ကြန်နှင့် နှစ်ဆန်းတစ်ရက်';

  @override
  String get holidayAboutThingyan =>
      'မြန်မာနှစ်ကုန်တွင် ကျင်းပသော ရေသဘင်ပွဲတော် ဖြစ်ပြီး အကြိုနေ့၊ အကျနေ့၊ အကြတ်နေ့၊ အတက်နေ့ ပြီးနောက် နှစ်ဆန်းတစ်ရက်နေ့ ရောက်ရှိသည်။ နှစ်ဟောင်း၏ အညစ်အကြေးများ ဆေးကြောရန် ရေပက်ကြပြီး ပွဲတော်ကာလနှင့် နှစ်ဆန်းရက်များတွင် ရုံးများ ပိတ်သည်။';

  @override
  String get holidayNameKarenNewYear => 'ကရင်နှစ်သစ်ကူးနေ့';

  @override
  String get holidayAboutKarenNewYear =>
      'ပြာသိုလဆန်း ၁ ရက်နေ့တွင် ကျရောက်သော ကရင်နှစ်သစ်ကူးနေ့ ဖြစ်ပြီး ရိုးရာ ကခုန်ဖျော်ဖြေမှုများဖြင့် ကျင်းပကြသည်။';

  @override
  String get holidayNameChineseNewYear => 'တရုတ်နှစ်သစ်ကူး';

  @override
  String get holidayAboutChineseNewYear =>
      'တရုတ်လူမျိုးများ မိသားစု စုံညီကြပြီး ခြင်္သေ့က၊ အနီရောင် စာအိတ်များဖြင့် ကျင်းပကြသော နှစ်သစ်ကူးပွဲ ဖြစ်သည်။';

  @override
  String get holidayNameShanNewYear => 'ရှမ်းနှစ်သစ်ကူး';

  @override
  String get holidayAboutShanNewYear =>
      'နတ်တော်လဆန်း ၁ ရက်နေ့တွင် ကျရောက်သော ရှမ်းနှစ်သစ်ကူးနေ့ ဖြစ်သည်။';

  @override
  String get holidayNameTaungpyone => 'တောင်ပြုန်းပွဲတော်';

  @override
  String get holidayAboutTaungpyone =>
      'မန္တလေးအနီး တောင်ပြုန်း၌ ဝါခေါင်လတွင် ကျင်းပသော တောင်ပြုန်း မင်းညီနောင် နတ်ပွဲတော် ဖြစ်သည်။';

  @override
  String get holidayNameYadanagu => 'ရတနာ့ဂူပွဲတော်';

  @override
  String get holidayAboutYadanagu =>
      'အမရပူရအနီး ရတနာ့ဂူ၌ တော်သလင်းလတွင် ကျင်းပသော ပုပ္ပါးမယ်တော် နတ်ပွဲတော် ဖြစ်သည်။';

  @override
  String get holidayNameMonNational => 'မွန်အမျိုးသားနေ့';

  @override
  String get holidayAboutMonNational =>
      'တပို့တွဲလပြည့်နေ့တွင် ကျရောက်ပြီး ဟံသာဝတီ (ပဲခူး) တည်ထောင်ခြင်းကို အောက်မေ့သည့် မွန်အမျိုးသားနေ့ ဖြစ်သည်။';

  @override
  String get holidayNameMothers => 'အမေများနေ့';

  @override
  String get holidayAboutMothers =>
      'မိခင်များကို ကျေးဇူးတင်ဂုဏ်ပြုသည့်နေ့ ဖြစ်သည်။';

  @override
  String get holidayNameFathers => 'အဖေများနေ့';

  @override
  String get holidayAboutFathers =>
      'ဖခင်များကို ကျေးဇူးတင်ဂုဏ်ပြုသည့်နေ့ ဖြစ်သည်။';

  @override
  String get holidayNameAuthors => 'စာဆိုတော်နေ့';

  @override
  String get holidayAboutAuthors =>
      'မြန်မာ စာရေးဆရာ၊ စာဆိုတော်များကို ဂုဏ်ပြုသည့်နေ့ ဖြစ်ပြီး စာပေဟောပြောပွဲ၊ စာအုပ်ပြပွဲများ ကျင်းပကြသည်။';

  @override
  String get holidayNameAungSanBirthday => 'ဗိုလ်ချုပ်အောင်ဆန်း မွေးနေ့';

  @override
  String get holidayAboutAungSanBirthday =>
      'မြန်မာ့လွတ်လပ်ရေး ဖခင် ဗိုလ်ချုပ်အောင်ဆန်း ၁၉၁၅ ခုနှစ် ဖေဖော်ဝါရီ ၁၃ ရက်တွင် မွေးဖွားခဲ့သည်။ ကလေးများနေ့ အဖြစ်လည်း ကျင်းပသည်။';

  @override
  String get holidayNameValentines => 'ချစ်သူများနေ့';

  @override
  String get holidayAboutValentines =>
      'ဖေဖော်ဝါရီ ၁၄ ရက်နေ့တွင် ကျရောက်သော ချစ်သူများနေ့ ဖြစ်သည်။';

  @override
  String get holidayNameAprilFools => 'ဧပြီအရူးနေ့';

  @override
  String get holidayAboutAprilFools =>
      'ဧပြီ ၁ ရက်နေ့တွင် ကျရောက်ပြီး ပျော်စရာ နောက်ပြောင်ကြသည့်နေ့ ဖြစ်သည်။';

  @override
  String get holidayNameEarth => 'ကမ္ဘာမြေနေ့';

  @override
  String get holidayAboutEarth =>
      'ဧပြီ ၂၂ ရက်နေ့တွင် ကမ္ဘာတစ်ဝန်း သဘာဝပတ်ဝန်းကျင် ထိန်းသိမ်းရေးကို အားပေးသည့်နေ့ ဖြစ်သည်။';

  @override
  String get holidayNameRedCross => 'ကြက်ခြေနီနေ့';

  @override
  String get holidayAboutRedCross =>
      'ကြက်ခြေနီ တည်ထောင်သူ ဟင်နရီ ဒူနန့် မွေးနေ့ ဖြစ်သော မေလ ၈ ရက်တွင် ကျရောက်သည့် ကမ္ဘာ့ကြက်ခြေနီနေ့ ဖြစ်သည်။';

  @override
  String get holidayNameUnitedNations => 'ကုလသမဂ္ဂနေ့';

  @override
  String get holidayAboutUnitedNations =>
      '၁၉၄၅ ခုနှစ် အောက်တိုဘာ ၂၄ ရက်တွင် ကုလသမဂ္ဂ ဖွဲ့စည်းတည်ထောင်ခြင်းကို အထိမ်းအမှတ်ပြုသည်။';

  @override
  String get holidayNameWorldTeachers => 'ကမ္ဘာ့ဆရာများနေ့';

  @override
  String get holidayAboutWorldTeachers =>
      'အောက်တိုဘာ ၅ ရက်နေ့တွင် ကျရောက်သော ယူနက်စကို၏ ကမ္ဘာ့ဆရာများနေ့ ဖြစ်သည်။';

  @override
  String get holidayNameHalloween => 'ဟယ်လိုဝင်း';

  @override
  String get holidayAboutHalloween =>
      'အောက်တိုဘာ ၃၁ ရက်နေ့ ညတွင် ဝတ်စုံများ ဝတ်ဆင်ကာ ပျော်ရွှင်ကြသည့်နေ့ ဖြစ်သည်။';

  @override
  String get holidaysSearchHint => 'ပိတ်ရက်များ ရှာရန်';

  @override
  String get holidaysFilterAll => 'အားလုံး';

  @override
  String get holidaysFilterPublic => 'ရုံးပိတ်ရက်';

  @override
  String get holidaysFilterReligious => 'ဘာသာရေး';

  @override
  String get holidaysFilterCultural => 'ယဉ်ကျေးမှု';

  @override
  String get holidaysFilterAnniversary => 'နှစ်ပတ်လည်နေ့များ';

  @override
  String get holidaysPublicHoliday => 'ရုံးပိတ်ရက်';

  @override
  String get holidaysObservance => 'အထိမ်းအမှတ်နေ့';

  @override
  String get holidaysKindNational => 'အမျိုးသား';

  @override
  String get holidaysKindReligious => 'ဘာသာရေး';

  @override
  String get holidaysKindCultural => 'ယဉ်ကျေးမှု';

  @override
  String get holidaysKindAnniversary => 'နှစ်ပတ်လည်နေ့';

  @override
  String get holidaysNextUp => 'နောက်ရုံးပိတ်ရက်';

  @override
  String holidaysDaysOff(int count) {
    return '$count ရက် ပိတ်သည်';
  }

  @override
  String holidaysDayCount(int count) {
    return '$count ရက်';
  }

  @override
  String holidaysDaysShort(String count) {
    return '$count ရက်';
  }

  @override
  String holidaysInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'နောက် $count ရက်',
      one: 'မနက်ဖြန်',
      zero: 'ယနေ့',
    );
    return '$_temp0';
  }

  @override
  String get holidaysNow => 'ယခု';

  @override
  String holidaysResults(int count, String year) {
    return '$year တွင် ပိတ်ရက် $count ခု';
  }

  @override
  String holidaysNoResults(String year, String query) {
    return '$year တွင် “$query” နှင့် ကိုက်ညီသည်များ မရှိပါ။';
  }

  @override
  String get holidaysSearchAllYears => 'နှစ်အားလုံးတွင် ရှာရန်';

  @override
  String holidaysYearsRange(String from, String to) {
    return '$from မှ $to အထိ';
  }

  @override
  String get holidaysEarlier => 'ယခုနှစ် အစောပိုင်း';

  @override
  String get holidaysComingUp => 'လာမည့်ရက်များ';

  @override
  String get holidaysNextYear => 'နောက်တစ်ကြိမ်';

  @override
  String get holidaysOtherYears => 'အခြားနှစ်များ';

  @override
  String get holidaysOpenInCalendar => 'ပြက္ခဒိန်တွင် ဖွင့်ရန်';

  @override
  String holidaysNotThisYear(String year) {
    return '$year တွင် မရှိပါ';
  }

  @override
  String get holidaysViewsSubtitle =>
      'နှစ်တစ်နှစ်၏ ပိတ်ရက်အားလုံးနှင့် သတိပေးချက်များ';

  @override
  String holidaysViewsFooter(int count, String year) {
    return '$year တွင် ရုံးပိတ်ရက် $count ခု ရှိသည်။';
  }

  @override
  String get viewsCalendarGroup => 'ပြက္ခဒိန်';

  @override
  String get viewsExploreGroup => 'ရှာဖွေရန်';

  @override
  String get holidayRemindMe => 'သတိပေးရန်';

  @override
  String get holidayReminderEvening => 'အကြိုညနေ ၆ နာရီ';

  @override
  String get holidayReminderMorning => 'ထိုနေ့ နံနက် ၈ နာရီ';

  @override
  String get holidayReminderBoth => 'အကြိုညနေနှင့် ထိုနေ့ နံနက်';

  @override
  String get holidayRemindersTitle => 'သတိပေးချက်များ';

  @override
  String get holidayRemindersWhen => 'အချိန်';

  @override
  String get holidayRemindersEveningOption => 'အကြိုညနေ';

  @override
  String get holidayRemindersMorningOption => 'ထိုနေ့ နံနက်';

  @override
  String get holidayRemindersBothOption => 'နှစ်ခုလုံး';

  @override
  String get holidayRemindersFollow => 'လိုက်ကြည့်ရန်';

  @override
  String get holidayRemindersAllPublic => 'ရုံးပိတ်ရက်အားလုံး';

  @override
  String holidayRemindersAllPublicSubtitle(int count, String year) {
    return '$year တွင် $count ရက်';
  }

  @override
  String get holidayRemindersFooter =>
      'သတိပေးချက်များသည် နောက် ရက် ၆၀ အတွက် ဖြစ်ပြီး အက်ပ်ဖွင့်တိုင်း အသစ်ပြင်ဆင်သည်။';

  @override
  String get holidayRemindersIncluded => 'ရုံးပိတ်ရက်အားလုံးတွင် ပါဝင်သည်';

  @override
  String get holidayRemindersPermissionDenied =>
      'Myanmar Calendar အတွက် အသိပေးချက်များ ပိတ်ထားသည်။ သတိပေးချက်များ ရရှိရန် ဖုန်း၏ ဆက်တင်တွင် ဖွင့်ပါ။';

  @override
  String holidayReminderTomorrow(String holiday) {
    return 'မနက်ဖြန်: $holiday';
  }

  @override
  String holidayReminderToday(String holiday) {
    return 'ယနေ့: $holiday';
  }

  @override
  String holidayReminderBodyPublic(String dates) {
    return 'ရုံးပိတ်ရက် · $dates';
  }

  @override
  String get whatsNewTitle => 'အသစ်များ';

  @override
  String whatsNewBadge(String version) {
    return '$version တွင် အသစ်';
  }

  @override
  String whatsNewFromVersion(String version) {
    return '$version မှ';
  }

  @override
  String whatsNewPageOf(int page, int count) {
    return '$count ခုအနက် $page';
  }

  @override
  String get whatsNewNext => 'နောက်တစ်ခု';

  @override
  String get whatsNewDone => 'ပြီးပါပြီ';

  @override
  String get whatsNewSeeAll => 'အပ်ဒိတ်အားလုံး ကြည့်ရန်';

  @override
  String whatsNewThisUpdate(String version) {
    return 'ဗားရှင်း $version · ယခုအပ်ဒိတ်';
  }

  @override
  String whatsNewVersion(String version) {
    return 'ဗားရှင်း $version';
  }

  @override
  String get whatsNewHolidaysTitle => 'ရုံးပိတ်ရက်များ';

  @override
  String get whatsNewHolidaysBody =>
      'နှစ်တစ်နှစ်၏ ပိတ်ရက်အားလုံးကို တစ်နေရာတည်းတွင် ကြည့်နိုင်သည်။ မြန်မာ သို့မဟုတ် အင်္ဂလိပ်လို ရှာနိုင်ပြီး နေ့တစ်နေ့ချင်း၏ အဓိပ္ပာယ်ကို ဖတ်ကာ အကြိုညနေတွင် သတိပေးချက် ရယူနိုင်သည်။';

  @override
  String get whatsNewHolidaysAction => 'ပိတ်ရက်များ ကြည့်ရန်';

  @override
  String get whatsNewWidgetsTitle => 'ပင်မစာမျက်နှာ ဝစ်ဂျက်အသစ်များ';

  @override
  String get whatsNewWidgetsBody =>
      'ယနေ့ရက်စွဲမှ သင်္ကြန်အထိ ရက်ရေတွက်ခြင်းအထိ ဝစ်ဂျက် ကိုးမျိုး၊ ပုံစံ ငါးမျိုး။ မည်သည့်နေ့ကိုမဆို နှိပ်၍ အက်ပ်တွင် ဖွင့်နိုင်သည်။';

  @override
  String get whatsNewWidgetsAction => 'ဝစ်ဂျက် ဆက်တင်';

  @override
  String get whatsNewWelcomeTitle => 'ကြိုဆိုမှု အသစ်';

  @override
  String get whatsNewWelcomeBody =>
      'အသုံးပြုသူအသစ်များအတွက် အက်ပ်မိတ်ဆက်နှင့် ဘာသာစကား၊ အသွင်အပြင်၊ ကိုယ်ရေးလုံခြုံမှု၊ သတိပေးချက်များကို အမြန်သတ်မှတ်နိုင်သည်။';

  @override
  String get whatsNewThemesTitle => 'ပြက္ခဒိန် ပုံစံများ';

  @override
  String get whatsNewThemesBody =>
      'စေတီ၊ ကျောက်စိမ်းမှ ကြယ်စုံညအထိ လ ပြက္ခဒိန်အတွက် ပုံစံ ဆယ့်နှစ်မျိုး၊ အလင်းနှင့် အမှောင် အရောင်များဖြင့်။';

  @override
  String get whatsNewThemesAction => 'ပုံစံ ရွေးရန်';

  @override
  String get whatsNewColorsTitle => 'စိတ်ကြိုက် အရောင်များ';

  @override
  String get whatsNewColorsBody =>
      'အက်ပ်တစ်ခုလုံးအတွက် အဓိကအရောင် တစ်ခု ရွေးနိုင်သည် သို့မဟုတ် အဆင့်မြင့်တွင် အရောင်တိုင်းကို ချိန်ညှိနိုင်သည်။';

  @override
  String get whatsNewColorsAction => 'အရောင် ရွေးရန်';

  @override
  String get whatsNewIconsTitle => 'အက်ပ် အိုင်ကွန်များ';

  @override
  String get whatsNewIconsBody =>
      'လ၊ သစ်တော၊ ရိုးရာ အပါအဝင် အက်ပ်အိုင်ကွန် ခြောက်မျိုးမှ ရွေးနိုင်သည်။';

  @override
  String get whatsNewIconsAction => 'အိုင်ကွန် ပြောင်းရန်';

  @override
  String get whatsNewStudioTitle => 'Calendar Studio';

  @override
  String get whatsNewStudioBody =>
      'နံရံကပ်၊ စားပွဲတင်နှင့် ဆိုရှယ်မီဒီယာ ပြက္ခဒိန်များကို ပုံစံများမှ ဒီဇိုင်းဆွဲပြီး ပုံနှိပ်ရန် PDF နှင့် ပုံများအဖြစ် ထုတ်ယူနိုင်သည်။';

  @override
  String get whatsNewStudioAction => 'Studio ဖွင့်ရန်';

  @override
  String get onboardingSkip => 'ကျော်ရန်';

  @override
  String get onboardingContinue => 'ဆက်ရန်';

  @override
  String get onboardingSetUp => 'အက်ပ်ကို ပြင်ဆင်ရန်';

  @override
  String get onboardingNotNow => 'နောက်မှ';

  @override
  String get onboardingStart => 'စတင်ရန်';

  @override
  String onboardingStep(int step, int count) {
    return 'အဆင့် $count ခုအနက် $step';
  }

  @override
  String get onboardingWelcomeTitle => 'မြန်မာ ပြက္ခဒိန်မှ ကြိုဆိုပါသည်';

  @override
  String get onboardingWelcomeBody =>
      'မြန်မာ ရက်စွဲနှင့် အင်္ဂလိပ် ရက်စွဲကို နေ့စဉ် ယှဉ်ကြည့်နိုင်ပါသည်။';

  @override
  String get onboardingCalendarsTitle => 'ပြက္ခဒိန် နှစ်ခု တစ်နေရာတည်း';

  @override
  String get onboardingCalendarsBody =>
      'နေ့တိုင်းတွင် မြန်မာရက်စွဲ၊ လ၏ အနေအထားနှင့် ဥပုသ်နေ့ကို ပြပြီး ဗေဒင် အချက်အလက်များကို တစ်ချက်နှိပ်ရုံဖြင့် ကြည့်နိုင်သည်။';

  @override
  String get onboardingHolidaysTitle => 'ပိတ်ရက် မလွတ်စေရ';

  @override
  String get onboardingHolidaysBody =>
      'ပိတ်ရက်အားလုံးကို ကြည့်ရှု ရှာဖွေနိုင်ပြီး ကိုယ်ပိုင် ပွဲစဉ်များ ထည့်ကာ အကြိုညနေတွင် သတိပေးချက် ရယူနိုင်သည်။';

  @override
  String get onboardingYoursTitle => 'ကိုယ်ပိုင်ပုံစံ ပြုလုပ်ပါ';

  @override
  String get onboardingYoursBody =>
      'အရောင်နှင့် ပြက္ခဒိန်ပုံစံများ ရွေးချယ်ပြီး ပင်မစာမျက်နှာ ဝစ်ဂျက်များ ထည့်ကာ Calendar Studio တွင် ပုံနှိပ်ရန် ပြက္ခဒိန်များ ဒီဇိုင်းဆွဲနိုင်သည်။';

  @override
  String get onboardingLanguagesTitle => 'ဘာသာစကား ရွေးချယ်ပါ';

  @override
  String get onboardingAppLanguage => 'အက်ပ် ဘာသာစကား';

  @override
  String get onboardingCalendarLanguageFooter =>
      'လအမည်များ၊ ပိတ်ရက်များနှင့် လ၏ အနေအထားများသည် ပြက္ခဒိန် ဘာသာစကားကို သုံးသည်။';

  @override
  String get onboardingLookTitle => 'အသွင်အပြင် ရွေးပါ';

  @override
  String get onboardingThemeAutomatic => 'အလိုအလျောက်';

  @override
  String get onboardingThemeLight => 'အလင်း';

  @override
  String get onboardingThemeDark => 'အမှောင်';

  @override
  String get onboardingColour => 'အရောင်';

  @override
  String get onboardingColourFooter =>
      'အရောင်နှင့် ပြက္ခဒိန်ပုံစံ ပိုမိုသည် ဆက်တင် › အသွင်အပြင် တွင် ရှိသည်။';

  @override
  String get onboardingPrivacyTitle =>
      'သင့်ပြက္ခဒိန်သည် သင့်ဖုန်းထဲတွင်သာ ရှိသည်';

  @override
  String get onboardingPrivacyBody =>
      'ပွဲစဉ်များနှင့် မှတ်စုများသည် သင့်ဖုန်းမှ ဘယ်တော့မှ ထွက်မသွားပါ။ အမည်မဖော်သော အချက်အလက်များ မျှဝေ၍ အက်ပ်ကို တိုးတက်အောင် ကူညီနိုင်သည်။';

  @override
  String get onboardingUsageStats => 'အသုံးပြုမှု စာရင်း';

  @override
  String get onboardingUsageStatsSubtitle =>
      'မည်သည့်စာမျက်နှာ သုံးသည်ကိုသာ၊ ပါဝင်သည့် အကြောင်းအရာ မဟုတ်ပါ';

  @override
  String get onboardingCrashReports => 'ပျက်ယွင်းမှု အစီရင်ခံစာ';

  @override
  String get onboardingCrashReportsSubtitle => 'အက်ပ် ပျက်သွားမှသာ ပို့သည်';

  @override
  String get onboardingPrivacyFooter =>
      'ဆက်တင် › ကိုယ်ရေးလုံခြုံမှုနှင့် ဒေတာ တွင် အချိန်မရွေး ပြောင်းနိုင်သည်။';

  @override
  String get onboardingNotificationsTitle => 'လိုအပ်ချိန်တွင် သတိပေးချက်';

  @override
  String get onboardingEventReminders => 'ပွဲစဉ် သတိပေးချက်';

  @override
  String get onboardingEventRemindersSubtitle =>
      'ပွဲစဉ်တစ်ခုချင်းအတွက် သင်ရွေးသည့်အချိန်တွင်';

  @override
  String get onboardingHolidayReminders => 'ပိတ်ရက် သတိပေးချက်';

  @override
  String get onboardingHolidayRemindersSubtitle =>
      'သင်လိုက်ကြည့်သော ပိတ်ရက်များ၏ အကြိုညနေတွင်';

  @override
  String get onboardingAllowNotifications => 'အသိပေးချက်များ ခွင့်ပြုရန်';

  @override
  String get onboardingDoneTitle => 'အားလုံး အဆင်သင့်ပါ';

  @override
  String onboardingDoneToday(String date) {
    return 'ယနေ့သည် $date ဖြစ်သည်။';
  }

  @override
  String get onboardingWidgetTipTitle => 'အကြံပြုချက် - ဝစ်ဂျက် ထည့်ပါ';

  @override
  String get onboardingWidgetTipBody =>
      'မြန်မာရက်စွဲကို ပင်မစာမျက်နှာတွင် ကြည့်ပါ။ နေရာလွတ်ကို ဖိထားပြီး Myanmar Calendar ကို ထည့်ပါ။';

  @override
  String get viewsMyanmarMonth => 'မြန်မာလ';

  @override
  String get viewsMyanmarMonthSubtitle => 'လဆန်း၊ လဆုတ် အလိုက် မြန်မာလ';

  @override
  String get viewsAgenda => 'အစီအစဉ်';

  @override
  String get viewsAgendaSubtitle =>
      'ရှေ့လာမည့် ရုံးပိတ်ရက်၊ ဥပုသ်၊ လပြည့်လကွယ်နှင့် သင့်ပွဲများ';

  @override
  String get dayDetailsComingUp => 'လာမည့်ရက်များ';

  @override
  String get dayDetailsNagahleCompass => 'နဂါးခေါင်း';

  @override
  String get dayDetailsNoAstrologicalDays => 'ထူးခြားသော ဗေဒင်ရက် မရှိပါ';

  @override
  String get repeatOn => 'နေ့များ';

  @override
  String get repeatEveryWeek => 'အပတ်တိုင်း';

  @override
  String repeatEveryWeeks(int count) {
    return '$count ပတ်တစ်ကြိမ်';
  }

  @override
  String get repeatEnds => 'ပြီးဆုံးမည်';

  @override
  String get repeatEndsOnDate => 'ရက်စွဲတစ်ခုတွင်';

  @override
  String get repeatEndsAfter => 'အကြိမ်ရေပြည့်လျှင်';

  @override
  String repeatTimes(int count) {
    return '$count ကြိမ်';
  }

  @override
  String repeatUntil(String date) {
    return '$date အထိ';
  }

  @override
  String get repeatTimePerDay => 'နေ့အလိုက် အချိန်သတ်မှတ်';

  @override
  String get repeatTimePerDayNote =>
      'အချိန်မတူသော နေ့များကို အချိန်တစ်ခုစီအတွက် အပတ်စဉ်ပွဲတစ်ခုစီအဖြစ် သိမ်းမည်။';

  @override
  String repeatEventsCreated(int count) {
    return 'ပွဲ $count ခု ဖန်တီးပြီး';
  }

  @override
  String get repeatPerDay => 'နေ့အလိုက်';
}
