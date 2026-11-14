import Foundation

/// Ticking an event done on a widget.
///
/// The widgets can't reach the app's events database, so a tick does two
/// things in the app group: it flips the event in the saved payload, so the
/// widget redraws at once, and it adds the tick to a queue the app applies
/// when it next starts or comes back (WidgetActions in
/// packages/features/home_widgets). Android does the same in WidgetTicks.kt.
enum WidgetTicks {
    /// Matches `WidgetActions.key` on the Dart side.
    static let queueKey = "widget_actions_v1"

    /// [raw] payload JSON with the occurrence of event [id] on [day] set to
    /// [done]; nil when the payload can't be read.
    static func applying(id: Int, day: String, done: Bool, to raw: String) -> String? {
        guard var payload = (try? JSONSerialization.jsonObject(with: Data(raw.utf8))) as? [String: Any],
              var events = payload["events"] as? [[String: Any]]
        else { return nil }
        for i in events.indices where (events[i]["id"] as? Int) == id && (events[i]["d"] as? String) == day {
            events[i]["done"] = done
        }
        payload["events"] = events
        guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// The queue [raw] with this tick added at the end.
    static func enqueue(id: Int, day: String, recurring: Bool, done: Bool, to raw: String?) -> String {
        var queue = raw
            .flatMap { try? JSONSerialization.jsonObject(with: Data($0.utf8)) as? [[String: Any]] } ?? []
        queue.append(["id": id, "d": day, "rec": recurring, "done": done])
        let data = (try? JSONSerialization.data(withJSONObject: queue)) ?? Data("[]".utf8)
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    /// Records a tick in the app group's payload and queue.
    static func toggle(id: Int, day: String, recurring: Bool, done: Bool, in defaults: UserDefaults?) {
        guard let defaults else { return }
        if let raw = defaults.string(forKey: PayloadStore.key),
           let updated = applying(id: id, day: day, done: done, to: raw) {
            defaults.set(updated, forKey: PayloadStore.key)
        }
        defaults.set(
            enqueue(id: id, day: day, recurring: recurring, done: done, to: defaults.string(forKey: queueKey)),
            forKey: queueKey
        )
    }
}
