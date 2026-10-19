/// What a holiday is, for the filters on the Holidays page.
enum HolidayKind { national, religious, cultural, anniversary }

/// One holiday the app knows about, independent of any year.
///
/// [names] are the English names `myanmar_calendar_dart` emits for its days
/// (Thingyan's five days share one entry). [officeClosed] says whether
/// government offices close, which the library's categories don't reliably
/// say. [aliases] are extra words search should match, in English and
/// Myanmar.
class HolidayEntry {
  const HolidayEntry({
    required this.id,
    required this.kind,
    this.names = const [],
    this.officeClosed = false,
    this.aliases = const [],
    this.fallbackName,
  });

  final String id;
  final HolidayKind kind;
  final List<String> names;
  final bool officeClosed;
  final List<String> aliases;

  /// The name to show for holidays not in the catalog (remote rules).
  final String? fallbackName;

  bool get isCustom => id.startsWith(HolidayCatalog.customPrefix);

  @override
  bool operator ==(Object other) => other is HolidayEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Every built-in holiday. Titles and descriptions are in the ARB files,
/// looked up by [HolidayEntry.id] (see `holiday_text.dart`).
abstract final class HolidayCatalog {
  static const customPrefix = 'custom:';

  /// The generic name the library gives extra days off ("bridge" days).
  static const bridgeName = 'Holiday';

  // National days.
  static const newYear = HolidayEntry(
    id: 'newYear',
    kind: HolidayKind.national,
    names: ["New Year's"],
    officeClosed: true,
  );
  static const independence = HolidayEntry(
    id: 'independence',
    kind: HolidayKind.national,
    names: ['Independence'],
    officeClosed: true,
    aliases: ['လွတ်လပ်ရေး'],
  );
  static const union = HolidayEntry(
    id: 'union',
    kind: HolidayKind.national,
    names: ['Union'],
    officeClosed: true,
    aliases: ['ပြည်ထောင်စု'],
  );
  static const peasants = HolidayEntry(
    id: 'peasants',
    kind: HolidayKind.national,
    names: ['Peasants'],
    officeClosed: true,
    aliases: ['Farmers'],
  );
  static const resistance = HolidayEntry(
    id: 'resistance',
    kind: HolidayKind.national,
    names: ['Resistance'],
    officeClosed: true,
    aliases: ['Armed Forces Day', 'တပ်မတော်နေ့'],
  );
  static const labour = HolidayEntry(
    id: 'labour',
    kind: HolidayKind.national,
    names: ['Labour'],
    officeClosed: true,
    aliases: ['May Day', 'Workers'],
  );
  static const martyrs = HolidayEntry(
    id: 'martyrs',
    kind: HolidayKind.national,
    names: ["Martyrs'"],
    officeClosed: true,
  );
  static const nationalDay = HolidayEntry(
    id: 'nationalDay',
    kind: HolidayKind.national,
    names: ['National Day'],
    officeClosed: true,
  );
  static const newYearsEve = HolidayEntry(
    id: 'newYearsEve',
    kind: HolidayKind.national,
    officeClosed: true,
    aliases: ['December 31'],
  );
  static const publicHoliday = HolidayEntry(
    id: 'publicHoliday',
    kind: HolidayKind.national,
    officeClosed: true,
    aliases: ['Holiday', 'ရုံးပိတ်ရက်'],
  );

  // Religious days.
  static const tabaung = HolidayEntry(
    id: 'tabaung',
    kind: HolidayKind.religious,
    names: ['Tabaung Pwe'],
    officeClosed: true,
    aliases: [
      'Full moon of Tabaung',
      'Tabaung festival',
      'တပေါင်းလပြည့်',
      'တပေါင်းပွဲ',
    ],
  );
  static const buddhaDay = HolidayEntry(
    id: 'buddhaDay',
    kind: HolidayKind.religious,
    names: ['Buddha'],
    officeClosed: true,
    aliases: [
      'Full moon of Kason',
      'Vesak',
      'Kason',
      'ကဆုန်လပြည့်',
      'ညောင်ရေသွန်ပွဲ',
    ],
  );
  static const lentStart = HolidayEntry(
    id: 'lentStart',
    kind: HolidayKind.religious,
    names: ['Start of Buddhist Lent'],
    officeClosed: true,
    aliases: [
      'Full moon of Waso',
      'Waso',
      'Dhammacakka',
      'ဝါဆိုလပြည့်',
      'ဝါဆို',
      'ဓမ္မစကြာ',
    ],
  );
  static const thadingyut = HolidayEntry(
    id: 'thadingyut',
    kind: HolidayKind.religious,
    names: ['End of Buddhist Lent'],
    officeClosed: true,
    aliases: [
      'Full moon of Thadingyut',
      'Festival of Lights',
      'End of Buddhist Lent',
      'သီတင်းကျွတ်လပြည့်',
      'ဝါကျွတ်',
      'မီးထွန်းပွဲ',
    ],
  );
  static const tazaungdaing = HolidayEntry(
    id: 'tazaungdaing',
    kind: HolidayKind.religious,
    names: ['Tazaungdaing'],
    officeClosed: true,
    aliases: [
      'Full moon of Tazaungmon',
      'Festival of Lights',
      'Tazaungmon',
      'တန်ဆောင်မုန်းလပြည့်',
      'မီးထွန်းပွဲ',
    ],
  );
  static const christmas = HolidayEntry(
    id: 'christmas',
    kind: HolidayKind.religious,
    names: ['Christmas'],
    officeClosed: true,
  );
  static const diwali = HolidayEntry(
    id: 'diwali',
    kind: HolidayKind.religious,
    names: ['Diwali'],
    officeClosed: true,
    aliases: ['Deepavali', 'ဒေဝါလီ'],
  );
  static const eidAlAdha = HolidayEntry(
    id: 'eidAlAdha',
    kind: HolidayKind.religious,
    names: ['Eid al-Adha'],
    officeClosed: true,
    aliases: ['Eid', 'Bakrid', 'အိဒ်'],
  );
  static const goodFriday = HolidayEntry(
    id: 'goodFriday',
    kind: HolidayKind.religious,
    names: ['Good Friday'],
  );
  static const easter = HolidayEntry(
    id: 'easter',
    kind: HolidayKind.religious,
    names: ['Easter'],
  );
  static const eidAlFitr = HolidayEntry(
    id: 'eidAlFitr',
    kind: HolidayKind.religious,
    names: ['Eid al-Fitr'],
    aliases: ['Eid', 'Ramadan', 'အိဒ်'],
  );
  static const mahathamaya = HolidayEntry(
    id: 'mahathamaya',
    kind: HolidayKind.religious,
    names: ['Mahathamaya'],
  );
  static const garudhamma = HolidayEntry(
    id: 'garudhamma',
    kind: HolidayKind.religious,
    names: ['Garudhamma'],
  );
  static const metta = HolidayEntry(
    id: 'metta',
    kind: HolidayKind.religious,
    names: ['Metta'],
  );

  // Cultural days.
  static const thingyan = HolidayEntry(
    id: 'thingyan',
    kind: HolidayKind.cultural,
    names: [
      'Thingyan Akyo',
      'Thingyan Akya',
      'Thingyan Akyat',
      'Thingyan Atat',
      "Myanmar New Year's Day",
    ],
    officeClosed: true,
    aliases: [
      'Water Festival',
      'Myanmar New Year',
      'Akyo',
      'Akya',
      'Akyat',
      'Atat',
      'သင်္ကြန်',
      'ရေသဘင်',
      'နှစ်ဆန်းတစ်ရက်',
      'နှစ်သစ်ကူး',
    ],
  );
  static const karenNewYear = HolidayEntry(
    id: 'karenNewYear',
    kind: HolidayKind.cultural,
    names: ["Karen New Year's"],
    officeClosed: true,
    aliases: ['ကရင်'],
  );
  static const chineseNewYear = HolidayEntry(
    id: 'chineseNewYear',
    kind: HolidayKind.cultural,
    names: ["Chinese New Year's"],
    aliases: ['Lunar New Year', 'Spring Festival', 'တရုတ်'],
  );
  static const shanNewYear = HolidayEntry(
    id: 'shanNewYear',
    kind: HolidayKind.cultural,
    names: ["Shan New Year's"],
    aliases: ['ရှမ်း'],
  );
  static const taungpyone = HolidayEntry(
    id: 'taungpyone',
    kind: HolidayKind.cultural,
    names: ['Taungpyone Pwe'],
    aliases: ['Nat festival'],
  );
  static const yadanagu = HolidayEntry(
    id: 'yadanagu',
    kind: HolidayKind.cultural,
    names: ['Yadanagu Pwe'],
    aliases: ['Nat festival'],
  );

  // Anniversaries and international days.
  static const monNational = HolidayEntry(
    id: 'monNational',
    kind: HolidayKind.anniversary,
    names: ['Mon National'],
    aliases: ['မွန်'],
  );
  static const mothers = HolidayEntry(
    id: 'mothers',
    kind: HolidayKind.anniversary,
    names: ['Mothers'],
  );
  static const fathers = HolidayEntry(
    id: 'fathers',
    kind: HolidayKind.anniversary,
    names: ['Fathers'],
  );
  static const authors = HolidayEntry(
    id: 'authors',
    kind: HolidayKind.anniversary,
    names: ['Authors'],
    aliases: ['Writers'],
  );
  static const aungSanBirthday = HolidayEntry(
    id: 'aungSanBirthday',
    kind: HolidayKind.anniversary,
    names: ['G. Aung San BD'],
    aliases: ['Children', 'Aung San', 'ကလေး'],
  );
  static const valentines = HolidayEntry(
    id: 'valentines',
    kind: HolidayKind.anniversary,
    names: ['Valentines'],
  );
  static const aprilFools = HolidayEntry(
    id: 'aprilFools',
    kind: HolidayKind.anniversary,
    names: ["April Fools'"],
  );
  static const earth = HolidayEntry(
    id: 'earth',
    kind: HolidayKind.anniversary,
    names: ['Earth'],
  );
  static const redCross = HolidayEntry(
    id: 'redCross',
    kind: HolidayKind.anniversary,
    names: ['Red Cross'],
  );
  static const unitedNations = HolidayEntry(
    id: 'unitedNations',
    kind: HolidayKind.anniversary,
    names: ['United Nations'],
    aliases: ['UN'],
  );
  static const worldTeachers = HolidayEntry(
    id: 'worldTeachers',
    kind: HolidayKind.anniversary,
    names: ["World Teachers'"],
  );
  static const halloween = HolidayEntry(
    id: 'halloween',
    kind: HolidayKind.anniversary,
    names: ['Halloween'],
  );

  static const all = <HolidayEntry>[
    newYear,
    independence,
    union,
    peasants,
    resistance,
    labour,
    martyrs,
    nationalDay,
    newYearsEve,
    publicHoliday,
    tabaung,
    buddhaDay,
    lentStart,
    thadingyut,
    tazaungdaing,
    christmas,
    diwali,
    eidAlAdha,
    goodFriday,
    easter,
    eidAlFitr,
    mahathamaya,
    garudhamma,
    metta,
    thingyan,
    karenNewYear,
    chineseNewYear,
    shanNewYear,
    taungpyone,
    yadanagu,
    monNational,
    mothers,
    fathers,
    authors,
    aungSanBirthday,
    valentines,
    aprilFools,
    earth,
    redCross,
    unitedNations,
    worldTeachers,
    halloween,
  ];

  static final Map<String, HolidayEntry> _byName = {
    for (final entry in all)
      for (final name in entry.names) name: entry,
  };

  static final Map<String, HolidayEntry> _byId = {for (final e in all) e.id: e};

  /// The entry for an English library name, or null for unknown names.
  static HolidayEntry? forName(String englishName) => _byName[englishName];

  /// The entry for [id], including custom ids built by [custom].
  static HolidayEntry? byId(String id) => _byId[id];

  /// An entry for a holiday the catalog doesn't know (a remote rule).
  static HolidayEntry custom(
    String name, {
    required HolidayKind kind,
    required bool officeClosed,
  }) => HolidayEntry(
    id: '$customPrefix$name',
    kind: kind,
    officeClosed: officeClosed,
    names: [name],
    fallbackName: name,
  );
}
