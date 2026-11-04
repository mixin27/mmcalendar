// "Good to know" for each holiday, in English. Keys are HolidayEntry ids,
// then HolidayGuidePart names. Sources: docs/holiday-guide-sources.md.

const holidayGuideEn = <String, Map<String, String>>{
  'newYear': {
    'happens':
        "1 January was a public holiday from 2018 to 2021 and again from 2025; Myanmar's own new year comes in April, after Thingyan. Cities hold countdown parties at hotels and public countdowns with fireworks, which vary from year to year.",
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
  'union': {
    'happens':
        "Marks the Panglong Agreement of 12 February 1947, when leaders of the Bamar, Shan, Kachin and Chin agreed to form a union. The main event is a dawn flag-raising ceremony in Nay Pyi Taw, with representatives of the ethnic groups in traditional dress; other cities hold their own events.",
    'practical':
        "A national public holiday: government offices and banks close. A bridge day is sometimes added next to it, so check that year's holiday list.",
    'where': "The square in front of City Hall in Nay Pyi Taw.",
  },
  'peasants': {
    'happens':
        "Honours farmers and farming. It was marked on 1 January until 1965, when 2 March became the official date. There is no big public celebration.",
    'practical':
        "A national public holiday: government offices and banks close. It sometimes falls on the same day as the Tabaung full moon.",
  },
  'resistance': {
    'happens':
        "Marks the start of the armed uprising against the Japanese occupation on 27 March 1945. First called Revolution Day, it has been called Armed Forces Day since 1955. The main event is a military parade in Nay Pyi Taw, shown on state TV.",
    'practical':
        "A national public holiday: government offices and banks close. The parade is a state event rather than a public festival.",
    'where': "The parade ground in Nay Pyi Taw.",
  },
  'labour': {
    'happens':
        "International Workers' Day. Unions and workers' groups often hold gatherings.",
    'practical':
        "A national public holiday: government offices and banks close.",
  },
  'martyrs': {
    'happens':
        "Remembers General Aung San and eight others killed at the Secretariat in Yangon on 19 July 1947. Officials and the martyrs' families lay wreaths at the Martyrs' Mausoleum, and flags fly at half-mast.",
    'practical':
        "A national public holiday: government offices and banks close. Public access to the mausoleum on the day has varied from year to year.",
    'etiquette':
        "At 10:37 am, the time of the attack, sirens and car horns sound and many people pause in silence. If people around you stop, stop with them.",
    'where':
        "The Martyrs' Mausoleum, near the north gate of Shwedagon, Yangon.",
  },
  'nationalDay': {
    'happens':
        "Marks the 1920 strike by Rangoon University students against the colonial University Act, seen as the start of the independence movement. It follows the Myanmar calendar, so it falls in November or December.",
    'practical':
        "A national public holiday: government offices and banks close.",
  },
  'newYearsEve': {
    'happens': "The last day of the Gregorian year.",
    'practical':
        "It was a public holiday from 2017 to 2021. Now it is a day off only in years when the government adds it as a bridge day; check that year's holiday list.",
  },
  'publicHoliday': {
    'happens':
        "An extra day off in the government's yearly holiday list: often a bridge day joining a holiday to the weekend, or a day off in place of a holiday that fell on a weekend.",
    'practical':
        "Offices and banks close as on any public holiday, and bridge days are often made up with a working Saturday. The list comes out near the end of the year before, and more days can be announced later.",
  },
  'christmas': {
    'happens':
        "Christians, most of them Chin, Kachin, Karen, Kayah and other ethnic peoples, go to church and visit family. Carol groups go from house to house in the weeks before, and malls and churches in Yangon put up lights. In some areas it has been quieter in recent years.",
    'practical':
        "A national public holiday: government offices and banks close.",
    'where':
        "St Mary's and Holy Trinity cathedrals in Yangon. It is biggest in Chin and Kachin states, where most people are Christian.",
  },
  'diwali': {
    'happens':
        "Hindu communities of Indian origin light oil lamps, decorate homes and temples and share sweets. Yangon holds an official celebration with Hindu associations.",
    'practical':
        "A one-day public holiday whose date the government announces each year; offices and banks close.",
    'etiquette': "Take off your shoes at temples and dress modestly.",
    'where':
        "Shri Kali Temple in Yangon's Little India, known for its painted roof.",
  },
  'eidAlAdha': {
    'happens':
        "Muslims attend morning prayers at mosques, visit family and share the meat of animals sacrificed for the festival. Celebrations have been low-key in recent years.",
    'practical':
        "A one-day public holiday whose date the government announces each year; offices and banks close.",
    'etiquette':
        "At mosques, dress modestly with shoulders and legs covered, take off your shoes, and ask before photographing people at prayer.",
    'where': "The mosques of downtown Yangon, around Pansodan Road.",
  },
  'eidAlFitr': {
    'happens':
        "Muslims end the fasting month of Ramadan with morning prayers at mosques, new clothes and family visits.",
    'practical': "Not a public holiday in Myanmar.",
    'etiquette':
        "At mosques, dress modestly with shoulders and legs covered, take off your shoes, and ask before photographing people at prayer.",
    'where': "The mosques of downtown Yangon, around Pansodan Road.",
  },
  'goodFriday': {
    'happens':
        "Christians remember the crucifixion of Jesus with church services.",
    'practical': "Not a public holiday in Myanmar.",
    'where':
        "St Mary's Cathedral, Myanmar's largest Catholic church, and Holy Trinity and Judson churches in Yangon.",
  },
  'easter': {
    'happens':
        "Christians celebrate the resurrection of Jesus with church services, many on Sunday morning.",
    'practical': "Not a public holiday; it always falls on a Sunday.",
    'where':
        "St Mary's Cathedral, Myanmar's largest Catholic church, and Holy Trinity and Judson churches in Yangon.",
  },
  'mahathamaya': {
    'happens':
        "Recalls the Buddha teaching the Mahasamaya Sutta to a great gathering of devas. At Shwedagon, monks are offered alms and groups walk around the stupa reciting the sutta. Nayon is also the month of the government's scripture examinations for monks.",
    'practical': "Not a public holiday.",
    'etiquette':
        "At pagodas, take off shoes and socks everywhere in the compound, cover shoulders and knees (a longyi can usually be rented at the gate) and walk around the stupa clockwise.",
    'where': "Shwedagon, Yangon.",
  },
  'garudhamma': {
    'happens':
        "One of the Buddhist full-moon days of Lent. At Shwedagon, people take precepts and offer robes and food to monks. Tawthalin is also the traditional month of boat-racing festivals.",
    'practical': "Not a public holiday.",
    'etiquette':
        "At pagodas, take off shoes and socks everywhere in the compound, cover shoulders and knees (a longyi can usually be rented at the gate) and walk around the stupa clockwise.",
    'where': "Shwedagon, Yangon.",
  },
  'metta': {
    'happens':
        "A day for spreading loving-kindness; pagodas offer meals to monks at dawn. Wagaung is also the month of salakabat, when donors draw lots carrying monks' names and give alms to the monk they draw. The custom lives on mainly in village monasteries.",
    'practical': "Not a public holiday.",
    'etiquette':
        "At pagodas, take off shoes and socks everywhere in the compound, cover shoulders and knees (a longyi can usually be rented at the gate) and walk around the stupa clockwise.",
    'where':
        "Shwedagon and Kaba Aye in Yangon; village monasteries for salakabat.",
  },
  'chineseNewYear': {
    'happens':
        "Chinese families honour their ancestors, visit temples and gather for reunion meals. Lion and dragon dancers parade through Chinatown, leaping between poles to reach red envelopes that shops hang high.",
    'practical':
        "The government has listed it as a public holiday since 2025; check that year's list for the exact days off. Chinatown is very crowded.",
    'where':
        "Yangon's Chinatown in Latha Township, including the Kheng Hock Keong temple on Strand Road.",
  },
  'taungpyone': {
    'happens':
        "A nat festival of about a week in Wagaung for the Shwe Hpyin brothers, two spirits honoured since King Anawrahta's time. Spirit mediums (nat kadaw) dance to hsaing waing music, and the brothers' statues are bathed and carried in procession. There are also markets and theatre.",
    'practical':
        "Tens of thousands come, and the first and last days are the busiest. It is hot, dusty and crowded.",
    'etiquette':
        "Many people avoid pork during the festival, out of respect for the brothers. Ask before photographing the mediums.",
    'where': "Taungpyone village, about 15 km north of Mandalay.",
  },
  'yadanagu': {
    'happens':
        "A nat festival for Popa Medaw, mother of the Taungpyone brothers, held soon after Taungpyone. Boats on the Ayeyarwady carry offerings, dancers and musicians, and many pilgrims arrive by boat.",
    'practical':
        "Smaller and calmer than Taungpyone. Amarapura is about 20 minutes from Mandalay.",
    'where': "Near Amarapura, south of Mandalay.",
  },
  'monNational': {
    'happens':
        "Marks the founding of Hanthawaddy (Bago). Mon communities hold ceremonies, literature and photo contests, traditional boxing, and Mon dance and music, with stalls of Mon food and crafts. Many people wear red longyis with white tops.",
    'practical':
        "Not a national public holiday. The main ceremony moves to a different town each year.",
    'where':
        "Mon State (Mawlamyine), Bago, Yangon and other places with Mon communities.",
  },
  'mothers': {
    'happens':
        "A day to thank mothers. This calendar shows it on the full moon of Pyatho, as in the Myanmar calendar; some people mark the international date in May instead.",
    'practical': "Not a public holiday.",
  },
  'fathers': {
    'happens': "A day to thank fathers, on the full moon of Tabaung.",
    'practical':
        "Not a holiday of its own, but the Tabaung full moon is a public holiday.",
  },
  'authors': {
    'happens':
        "Honours Myanmar's writers and poets. First held in 1944, it is usually organised by writers' associations, with tributes to senior writers, literary talks and contests; national literary awards are often presented around the same time.",
    'practical': "Not a public holiday.",
    'where': "Writers' associations in Yangon and other cities.",
  },
  'aungSanBirthday': {
    'happens':
        "General Aung San, leader of the independence movement, was born on 13 February 1915. The day is also kept as Children's Day, mainly with activities in schools.",
    'practical':
        "Not a public holiday of its own. It falls the day after Union Day, so it is sometimes a bridge day.",
  },
  'valentines': {
    'happens':
        "Popular with young people in cities; shops and malls set up gift displays and promotions.",
    'practical': "Not a public holiday.",
  },
  'aprilFools': {
    'happens': "A day for practical jokes.",
    'practical':
        "Not a public holiday. It falls about two weeks before Thingyan.",
  },
  'earth': {
    'happens': "A worldwide day for protecting the environment.",
    'practical': "Not a public holiday.",
  },
  'redCross': {
    'happens':
        "The Myanmar Red Cross Society began in 1920 and became a national society in 1937. Its volunteers help at festivals, disasters and other emergencies.",
    'practical': "Not a public holiday.",
  },
  'unitedNations': {
    'happens':
        "Myanmar joined the United Nations in 1948, and a Myanmar diplomat, U Thant, was its Secretary-General from 1961 to 1971.",
    'practical': "Not a public holiday.",
  },
  'worldTeachers': {
    'happens':
        "Myanmar has a strong tradition of respect for teachers: students pay respects (gadaw) to them, especially around Thadingyut, and some schools hold ceremonies on 5 October.",
    'practical': "Not a public holiday.",
  },
  'halloween': {
    'happens':
        "Marked mainly with costume parties at bars and clubs in Yangon; it is little known elsewhere.",
    'practical': "Not a public holiday.",
  },
};
