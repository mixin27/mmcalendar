import Foundation
import WatchConnectivity

/// Sends the widgets' payload (`widget_data_v2`) to the Apple Watch app.
///
/// The payload is read from the app group, where the Flutter side saves it
/// for the iPhone widgets. It goes over as the session's application
/// context: WatchConnectivity keeps only the newest one and delivers it in
/// the background, which is exactly what a "current data" payload needs.
/// It is zlib-compressed (about 68 KB of JSON becomes about 7 KB).
///
/// It is sent when Flutter asks (`dev.mixin27.mmcalendar/watch` › `sync`,
/// after each widget refresh), when the session activates, when the watch
/// app is installed, and in reply when the watch asks because its copy is
/// missing or old; that message also wakes this app in the background.
final class WatchSync: NSObject, WCSessionDelegate {
    static let shared = WatchSync()

    static let appGroup = "group.dev.mixin27.mmcalendar"
    static let payloadKey = "widget_data_v2"
    /// The compressed payload in the application context and in replies.
    /// Matches `WatchKeys.payload` on the watch.
    static let contextKey = "widget_data_v2_z"
    /// What the watch sends to ask for the payload.
    static let requestKey = "request"

    private var lastSent: Data?

    func start() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// The current payload, compressed; nil before Flutter has written one.
    private func compressedPayload() -> Data? {
        guard let raw = UserDefaults(suiteName: Self.appGroup)?.string(forKey: Self.payloadKey) else {
            return nil
        }
        return try? (Data(raw.utf8) as NSData).compressed(using: .zlib) as Data
    }

    /// Updates the watch's copy unless it already has this payload.
    func send() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled,
              let data = compressedPayload(),
              data != lastSent
        else { return }
        do {
            try session.updateApplicationContext([Self.contextKey: data])
            lastSent = data
        } catch {
            NSLog("Watch sync: %@", error.localizedDescription)
        }
    }

    // MARK: - WCSessionDelegate

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if activationState == .activated { DispatchQueue.main.async { self.send() } }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    /// The user switched watches: activate again for the new one.
    func sessionDidDeactivate(_ session: WCSession) {
        lastSent = nil
        session.activate()
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        DispatchQueue.main.async { self.send() }
    }

    /// The watch asks when its copy is missing or old: reply with the
    /// payload itself, and update the context too.
    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        guard message[Self.requestKey] != nil else { return replyHandler([:]) }
        DispatchQueue.main.async {
            self.lastSent = nil
            self.send()
            replyHandler(self.compressedPayload().map { [Self.contextKey: $0] } ?? [:])
        }
    }
}
