import Foundation
import WatchConnectivity
import WatchKit
import WidgetKit

/// The watch's copy of the iPhone's widget payload.
///
/// The iPhone sends `widget_data_v2`, zlib-compressed, as the session's
/// application context, and in reply when the watch asks
/// (ios/Runner/WatchSync.swift). It is saved to the watch's app group under
/// the same key the iPhone widgets read, so `PayloadStore.load()` works here
/// unchanged, for this app and for the complications.
@MainActor
final class WatchStore: NSObject, ObservableObject {
    static let shared = WatchStore()

    /// Ask the iPhone again when the data starts this many days ago.
    static let staleAfterDays = 7

    @Published private(set) var payload: WidgetPayload? = PayloadStore.load()

    /// Background refresh tasks to finish once received content is saved.
    private var pendingTasks: [WKWatchConnectivityRefreshBackgroundTask] = []

    func start() {
        guard WCSession.isSupported(), WCSession.default.delegate == nil else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Asks the iPhone for the payload when it's missing or old. The
    /// message wakes the iPhone app in the background, if the phone is near.
    func requestIfStale(now: Date = .now) {
        guard Self.isStale(payload, now: now) else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isReachable else { return }
        session.sendMessage([WatchKeys.request: "payload"], replyHandler: { reply in
            let data = reply[WatchKeys.payload] as? Data
            Task { @MainActor in if let data { self.save(compressed: data) } }
        }, errorHandler: nil)
    }

    nonisolated static func isStale(_ payload: WidgetPayload?, now: Date) -> Bool {
        guard let payload, let start = DayKey.date(payload.start) else { return true }
        let age = Calendar.current.dateComponents([.day], from: start, to: now).day ?? .max
        return age >= staleAfterDays
    }

    func handle(_ task: WKWatchConnectivityRefreshBackgroundTask) {
        pendingTasks.append(task)
        start()
        finishTasksIfIdle()
    }

    /// Unpacks a payload from the iPhone and saves it for the app and the
    /// complications. Anything that doesn't decode is ignored.
    func save(compressed: Data) {
        guard let raw = Self.unpack(compressed),
              let data = raw.data(using: .utf8),
              (try? JSONDecoder().decode(WidgetPayload.self, from: data)) != nil
        else { return }
        if raw == UserDefaults(suiteName: PayloadStore.appGroup)?.string(forKey: PayloadStore.key) { return }
        UserDefaults(suiteName: PayloadStore.appGroup)?.set(raw, forKey: PayloadStore.key)
        payload = PayloadStore.load()
        WidgetCenter.shared.reloadAllTimelines()
    }

    nonisolated static func unpack(_ compressed: Data) -> String? {
        guard let data = try? (compressed as NSData).decompressed(using: .zlib) as Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func finishTasksIfIdle() {
        guard !WCSession.default.hasContentPending else { return }
        for task in pendingTasks { task.setTaskCompletedWithSnapshot(false) }
        pendingTasks.removeAll()
    }
}

enum WatchKeys {
    /// Matches `WatchSync.requestKey` on the iPhone.
    static let request = "request"
    /// Matches `WatchSync.contextKey` on the iPhone.
    static let payload = "widget_data_v2_z"
}

extension WatchStore: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        // A context that arrived while the app wasn't running.
        let received = session.receivedApplicationContext[WatchKeys.payload] as? Data
        Task { @MainActor in
            if let received { self.save(compressed: received) }
            self.requestIfStale()
            self.finishTasksIfIdle()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.requestIfStale() }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        let data = context[WatchKeys.payload] as? Data
        Task { @MainActor in
            if let data { self.save(compressed: data) }
            self.finishTasksIfIdle()
        }
    }
}
