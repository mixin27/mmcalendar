// "Good to know" for each holiday, in English. Keys are HolidayEntry ids,
// then HolidayGuidePart names. Sources: docs/holiday-guide-sources.md.

const holidayGuideEn = <String, Map<String, String>>{
  'newYear': {
    'happens':
        "The Gregorian New Year has been a public holiday since 2018; Myanmar's own new year comes in April, after Thingyan. Cities hold countdown parties at hotels and public countdowns with fireworks, which vary from year to year.",
    'practical':
        "A one-day public holiday: schools, government offices and banks close. New Year's Eve events change every year, so check locally.",
    'where':
        "Yangon's public countdowns have been held at places such as Kandawgyi Park and near Shwedagon.",
  },
  'independence': {
    'happens':
        "Marks independence from Britain on 4 January 1948. Towns hold fairs, sports and concerts, with traditional games such as tug-of-war, sack races and climbing a greasy pole, and there is an official ceremony in Nay Pyi Taw.",
    'practical':
        "A national public holiday: government offices and banks close. Fewer neighbourhood fairs have been held in recent years.",
    'where':
        "Neighbourhood fairs in Yangon and other cities, and the official ceremony in Nay Pyi Taw.",
  },
  'tabaung': {
    'happens':
        "The full moon of Tabaung, usually in March, falls in the last month of the Myanmar year and is the high season for pagoda festivals. Shwedagon's is the biggest, with prayers, offerings and crowds walking around the stupa. In Upper Myanmar people build small sand pagodas, usually of five tiers, and walk around them with fruit and flowers.",
    'practical':
        "A one-day public holiday. It is not the same as Peasants' Day (2 March), though the two sometimes fall on the same day. Yangon's big pagodas are crowded on the full-moon day.",
    'etiquette':
        "At pagodas, take off shoes and socks everywhere in the compound, cover shoulders and knees (a longyi can usually be rented at the gate) and walk around the stupa clockwise.",
    'where':
        "Shwedagon in Yangon; sand-pagoda festivals in Mandalay; and big pagoda festivals at Shwesettaw near Minbu and at Kakku in Shan State.",
  },
  'buddhaDay': {
    'happens':
        "The full moon of Kason, usually in May, marks the Buddha's birth, enlightenment and passing away. Monks and lay people walk in procession to the Bodhi trees at pagodas and monasteries and pour water on their roots.",
    'practical':
        "A one-day public holiday. The watering ceremonies are usually held in the morning, when big pagodas are crowded.",
    'etiquette':
        "At pagodas, take off shoes and socks everywhere in the compound, cover shoulders and knees (a longyi can usually be rented at the gate) and walk around the stupa clockwise. Watch quietly, and ask before photographing monks.",
    'where':
        "At Shwedagon, the pagoda trustees lead the watering of a Bodhi tree on the south-east of the platform, and thousands join in. Pagodas and monasteries across the country hold the same ceremony.",
  },
  'lentStart': {
    'happens':
        "The full moon of Waso, usually in July, starts the three-month Buddhist Lent, when monks stay in their monasteries. It is also Dhammasetkya Day, the anniversary of the Buddha's first sermon. People offer Waso robes and large candles to monks, many keep extra precepts, and novice ordinations (shinbyu) are held.",
    'practical':
        "A one-day public holiday, in the rainy season. Through Lent, many people keep extra precepts on full-moon, new-moon and quarter-moon days.",
    'etiquette':
        "Offer monks food, robes or other things they can use, not money; put money in the donation boxes. Women don't touch monks. Give up your seat to monks on buses.",
    'where':
        "Shwedagon holds a Dhammasetkya ceremony and Waso robe offering on the day, and Botahtaung Pagoda also draws large crowds.",
  },
  'thadingyut': {
    'happens':
        "The full moon of Thadingyut, usually in October, ends the three-month Buddhist Lent. For three nights homes, streets and pagodas are lit with candles and lanterns, recalling the Buddha's descent from heaven by stairways of light. Younger people pay respects to parents, teachers and elders with fruit and gifts, and are blessed and often given pocket money. There are theatre shows, fairs and free food stalls.",
    'practical':
        "The biggest festival after Thingyan: offices and many businesses close for several days, and buses and trains are busy. Pagodas are crowded on the full-moon evening.",
    'etiquette':
        "At pagodas, take off shoes and socks everywhere in the compound, cover shoulders and knees (a longyi can usually be rented at the gate) and walk around the stupa clockwise. Don't point your feet at Buddha images or monks.",
    'where':
        "Shwedagon and downtown Yangon are the busiest. Some towns add their own customs, such as floating oil lamps down the river at Shwegyin and floating alms bowls out to sea at Dawei.",
  },
  'tazaungdaing': {
    'happens':
        "The full moon of Tazaungmon, usually in November, closes the season of offering robes to monks (kathina). It is another festival of lights, with lanterns and fire balloons. On the eve and the full-moon night, teams weave a robe overnight in matho thingan contests and offer it before dawn. People eat a salad of mezali buds, and young men play pranks on the full-moon night.",
    'practical':
        "The full-moon day and the day before are public holidays. Taunggyi's balloon festival runs for about a week and draws tens of thousands of people, so plan where to stay early.",
    'etiquette':
        "In Taunggyi, keep well clear of balloons coming down: balloons carrying fireworks have fallen into crowds and killed people. At pagodas, take off shoes and socks everywhere in the compound, cover shoulders and knees (a longyi can usually be rented at the gate) and walk around the stupa clockwise. Give monks food rather than money, and ask before photographing them.",
    'where':
        "Taunggyi's balloon ground: huge balloons in many shapes, and at night seinnapan balloons hung with small lanterns and balloons carrying fireworks. Shwedagon and Botahtaung hold the best-known robe-weaving contests.",
  },
  'thingyan': {
    'happens':
        "Four or five days of water throwing in mid-April, ending on Myanmar New Year's Day; the water washes away the old year's bad luck. Streets fill with pandals (spraying stages that are also dance floors), yein dance troupes, satirical thangyat songs and free food stalls. Many people also keep precepts at monasteries, wash their elders' hair and release fish to earn merit.",
    'practical':
        "Offices, banks and many shops and restaurants close for the whole holiday, often about ten days. Many bus routes stop and trains run less often, so book transport well ahead. April is one of the hottest months. Keep your phone, money and passport in a waterproof bag.",
    'etiquette':
        "Outdoors, expect to get wet. Don't splash monks or pregnant women; most people also spare elders and small children, and anyone who signals they want to stay dry. Wear dark, quick-drying, modest clothes. The last day, Atat, is calmer, and New Year's Day is for merit-making, not splashing.",
    'where':
        "In Yangon, pandals line Kandawgyi Lake and Kabaraye Road. In Mandalay, pandals ring the palace moat and decorated floats parade through the city. Smaller towns have their own celebrations.",
  },
  'karenNewYear': {
    'happens':
        "On the 1st of Pyatho (December or January), Karen communities mark the end of the rice harvest with don and bamboo dances, songs, speeches and food, and raise the Karen flag. The bronze frog drum, a Karen symbol, appears on the flag.",
    'practical':
        "A national public holiday: government offices and banks close. Celebrations are biggest where Karen people live, and in some areas they have been smaller in recent years.",
    'where':
        "Hpa-an in Kayin State holds don dance contests and Karen kickboxing, and Karen communities in Yangon, including Insein Township, hold flag ceremonies and gatherings.",
  },
  'shanNewYear': {
    'happens':
        "On the 1st waxing of Nadaw (late November or December), Shan communities celebrate with traditional dances, Shan dress and long-drum music. It began as a harvest festival; people also pay respects to elders, offer food to monks and pray at pagodas.",
    'practical':
        "Not a national public holiday, so offices and banks stay open. Shan community groups organise the events, so dates and venues can change; check locally.",
    'where': "The largest gatherings are in Taunggyi, Kengtung and Muse.",
  },
};
