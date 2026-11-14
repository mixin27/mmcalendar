import XCTest
@testable import MyanmarCalendarWatch

/// WidgetTicks lives in ios/WidgetShared, which the watch app also builds,
/// so the iPhone widgets' tick logic is tested here.
final class WidgetTicksTests: XCTestCase {
    private let payload = """
    {"v":2,"events":[
      {"id":1,"d":"2026-11-13","ti":"Pagoda","c":4281293802,"done":false},
      {"id":1,"d":"2026-11-20","ti":"Pagoda","c":4281293802,"done":false},
      {"id":2,"d":"2026-11-13","ti":"Dentist","c":4281293802,"done":false},
      {"id":null,"d":"2026-11-13","ti":"Holiday","c":4281293802,"done":false}
    ]}
    """

    private func done(_ raw: String) throws -> [Bool] {
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any])
        let events = try XCTUnwrap(object["events"] as? [[String: Any]])
        return events.map { $0["done"] as? Bool ?? false }
    }

    func testTicksOnlyThatDaysOccurrence() throws {
        let updated = try XCTUnwrap(WidgetTicks.applying(id: 1, day: "2026-11-13", done: true, to: payload))
        XCTAssertEqual(try done(updated), [true, false, false, false])
        let untick = try XCTUnwrap(WidgetTicks.applying(id: 1, day: "2026-11-13", done: false, to: updated))
        XCTAssertEqual(try done(untick), [false, false, false, false])
    }

    func testLeavesAnUnreadablePayloadAlone() {
        XCTAssertNil(WidgetTicks.applying(id: 1, day: "2026-11-13", done: true, to: "not json"))
        XCTAssertNil(WidgetTicks.applying(id: 1, day: "2026-11-13", done: true, to: "{}"))
    }

    func testQueuesTicksInOrderForTheApp() throws {
        let first = WidgetTicks.enqueue(id: 1, day: "2026-11-13", recurring: true, done: true, to: nil)
        let both = WidgetTicks.enqueue(id: 2, day: "2026-11-14", recurring: false, done: false, to: first)
        let queue = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(both.utf8)) as? [[String: Any]])
        XCTAssertEqual(queue.count, 2)
        XCTAssertEqual(queue[0]["id"] as? Int, 1)
        XCTAssertEqual(queue[0]["d"] as? String, "2026-11-13")
        XCTAssertEqual(queue[0]["rec"] as? Bool, true)
        XCTAssertEqual(queue[0]["done"] as? Bool, true)
        XCTAssertEqual(queue[1]["id"] as? Int, 2)
        XCTAssertEqual(WidgetTicks.enqueue(id: 3, day: "2026-11-13", recurring: false, done: true, to: "oops").count > 2, true)
    }

    func testToggleWritesBothToTheAppGroup() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "widget-ticks-test"))
        defaults.removePersistentDomain(forName: "widget-ticks-test")
        defaults.set(payload, forKey: PayloadStore.key)
        WidgetTicks.toggle(id: 2, day: "2026-11-13", recurring: false, done: true, in: defaults)
        XCTAssertEqual(try done(try XCTUnwrap(defaults.string(forKey: PayloadStore.key))), [false, false, true, false])
        XCTAssertTrue(try XCTUnwrap(defaults.string(forKey: WidgetTicks.queueKey)).contains("\"id\":2"))
        // The payload still decodes for the widgets.
        _ = try JSONSerialization.jsonObject(with: Data(try XCTUnwrap(defaults.string(forKey: PayloadStore.key)).utf8))
        defaults.removePersistentDomain(forName: "widget-ticks-test")
    }
}
