# Store screenshots

Captioned in Myanmar, at the sizes each store asks for. They are made from
real app captures with demo data:

```bash
scripts/capture_store_screens.sh            # iphone, ipad, android_phone, android_tablet
cd apps/myanmar_calendar && flutter test tool/store_frames_test.dart
```

| Folder | Size | Where it goes |
| --- | --- | --- |
| `app_store/iphone_6_3/` | 1206 × 2622 | App Store Connect › iPhone with Dynamic Island (medium display) |
| `app_store/iphone_duo/` | 1398 × 2034 | App Store Connect › iPhone Duo (the iPhone shots, framed; no Duo simulator yet) |
| `app_store/ipad_13/` | 2064 × 2752 | App Store Connect › iPad 13" display |
| `app_store/header.png` | 3840 × 1646 | App Store Connect › Header and Search Results › Header |
| `app_store/search_results.png` | 3840 × 2560 | App Store Connect › Header and Search Results › Search Results |
| `play_store/phone/` | 1080 × 1920 | Play Console › Phone screenshots (2–8) |
| `play_store/tablet_10/` | 1440 × 2560 | Play Console › 10-inch tablet screenshots |
| `play_store/feature_graphic.png` | 1024 × 500 | Play Console › Feature graphic |

Order, by file name:

1. Home: Almanac grid
2. Day details: astrology and the Nagahle compass
3. Holidays
4. Myanmar month
5. Class timetable (weekly repeat)
6. Calendar Studio
7. Grid layouts
8. Converter

## Listing text

| File | Limit | Where it goes |
| --- | --- | --- |
| `play_store/title.txt`, `title_my.txt` | 30 characters | Play Console › App name (English, Myanmar); English matches the App Store name |
| `play_store/short_description.txt`, `short_description_my.txt` | 80 characters | Play Console › Short description (English, Myanmar) |
| `play_store/full_description.txt`, `full_description_my.txt` | 4,000 characters | Play Console › Full description (English, Myanmar) |
| `play_store/release_notes.txt` | 500 characters per language | Play Console › Release › Release notes (paste as is; drop `<my-MM>` if the listing has no Myanmar translation) |
