import SwiftUI
import WatchKit

@main
struct MyanmarCalendarWatchApp: App {
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var delegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WatchRootView(store: WatchStore.shared)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { WatchStore.shared.requestIfStale() }
        }
    }
}

/// Starts WatchConnectivity at launch, including background launches the
/// system makes to deliver a payload from the iPhone.
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        Task { @MainActor in WatchStore.shared.start() }
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let task = task as? WKWatchConnectivityRefreshBackgroundTask {
                Task { @MainActor in WatchStore.shared.handle(task) }
            } else {
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
