import XCTest
@testable import MyanmarCalendarWatch

/// The watch only draws `widget_data_v2`; these check it reads the payload
/// the way the iPhone writes it and knows when to ask for a new one.
final class WatchPayloadTests: XCTestCase {
    private func payload(start: String = "2026-11-13", digits: String = "၀၁၂၃၄၅၆၇၈၉") throws -> WidgetPayload {
        let json = """
        {
          "v": 2, "lang": "my", "gen": "2026-11-13T08:00:00.000", "start": "\(start)",
          "s": {
            "today": "ယနေ့", "tomorrow": "မနက်ဖြန်", "inDays": "{n} ရက်အကြာ", "daysUnit": "ရက်",
            "comingUp": "လာမည့်", "events": "ပွဲများ", "noEvents": "မရှိ", "allDay": "တစ်နေကုန်",
            "nextGoodDay": "", "goodDay": "", "avoidDay": "", "plainDay": "", "myanmarYear": "",
            "thingyan": "သင်္ကြန်", "fullMoonIn": "", "newMoonIn": "", "holidays": "", "digits": "\(digits)",
            "sabbath": "ဥပုသ်", "sabbathEve": "အဖိတ်",
            "moonPhases": ["", "", "", ""], "weekdays": ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
            "weekdaysShort": ["S", "M", "T", "W", "T", "F", "S"],
            "months": ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],
            "monthsShort": ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],
            "westernDigits": "0123456789"
          },
          "days": [
            {"d": "2026-11-13", "wd": 5, "my": "တန်ဆောင်မုန်း လဆုတ် ၉", "lu": "လဆုတ် ၉", "ln": "၉",
             "ph": 2, "il": 0.6, "wx": false, "hol": [], "sab": 0, "good": [], "avoid": [], "info": []},
            {"d": "2026-11-14", "wd": 6, "my": "တန်ဆောင်မုန်း လဆုတ် ၁၀", "lu": "လဆုတ် ၁၀", "ln": "၁၀",
             "ph": 2, "il": 0.5, "wx": false, "hol": ["Holiday"], "sab": 1, "good": [], "avoid": [], "info": []}
          ],
          "months": {}, "upcoming": [{"d": "2026-11-14", "k": "sabbath", "n": "ဥပုသ်"}],
          "thingyan": null,
          "events": [{"d": "2026-11-13", "t": "09:30", "ti": "Pagoda", "c": -16777216, "id": 1, "done": false}],
          "year": {"n": "1388", "start": "2026-04-16", "end": "2027-04-15", "month": ""},
          "styles": {}, "prefs": {"style": "app", "hol": true, "sab": true, "ast": true, "ev": true, "cd": "fullMoon"}
        }
        """
        return try JSONDecoder().decode(WidgetPayload.self, from: Data(json.utf8))
    }

    private func date(_ key: String) -> Date { DayKey.date(key)! }

    func testReadsTheDaysAndEvents() throws {
        let p = try payload()
        let friday = try XCTUnwrap(p.day(for: date("2026-11-13")))
        XCTAssertEqual(friday.my, "တန်ဆောင်မုန်း လဆုတ် ၉")
        XCTAssertEqual(p.day(for: date("2026-11-14"))?.isSabbath, true)
        XCTAssertNil(p.day(for: date("2026-11-20")))
        XCTAssertEqual(p.events(on: date("2026-11-13")).map(\.ti), ["Pagoda"])
    }

    func testWritesWesternDatesAndCountdowns() throws {
        let p = try payload()
        let day = try XCTUnwrap(p.day(for: date("2026-11-13")))
        XCTAssertEqual(p.westernDate(date("2026-11-13"), day), "Fri, 13 Nov 2026")
        XCTAssertEqual(p.westernDigits("09:30"), "09:30")
        XCTAssertEqual(p.countdown(1), "မနက်ဖြန်")
        XCTAssertEqual(p.countdown(12), "၁၂ ရက်အကြာ")
    }

    /// The iPhone compresses with NSData's zlib, as WatchSync does.
    func testUnpacksWhatTheIPhoneSends() throws {
        let raw = "{\"v\":2,\"my\":\"တန်ဆောင်မုန်း\"}"
        let packed = try (Data(raw.utf8) as NSData).compressed(using: .zlib) as Data
        XCTAssertEqual(WatchStore.unpack(packed), raw)
        XCTAssertNil(WatchStore.unpack(Data("not zlib".utf8)))
    }

    func testAsksTheIPhoneWhenDataIsMissingOrAWeekOld() throws {
        XCTAssertTrue(WatchStore.isStale(nil, now: date("2026-11-13")))
        XCTAssertFalse(WatchStore.isStale(try payload(start: "2026-11-13"), now: date("2026-11-19")))
        XCTAssertTrue(WatchStore.isStale(try payload(start: "2026-11-13"), now: date("2026-11-20")))
    }
}
