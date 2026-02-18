//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit
import Sparkle

@MainActor
final class SparkleUserDriverDelegate: NSObject, SPUStandardUserDriverDelegate {
    private final class TrackedWindow {
        weak var window: NSWindow?
        let originalLevel: NSWindow.Level

        init(window: NSWindow, originalLevel: NSWindow.Level) {
            self.window = window
            self.originalLevel = originalLevel
        }
    }

    private var trackedWindows: [TrackedWindow] = []
    private var windowObserverTokens: [NSObjectProtocol] = []
    private var appObserverTokens: [NSObjectProtocol] = []
    private var isUpdateSessionActive = false

    override init() {
        super.init()
        registerObservers()
    }

    var supportsGentleScheduledUpdateReminders: Bool {
        true
    }

    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        beginUpdateSession()
    }

    func standardUserDriverWillShowModalAlert() {
        beginUpdateSession()
    }

    func standardUserDriverDidShowModalAlert() {
        beginUpdateSession()
    }

    func standardUserDriverWillFinishUpdateSession() {
        isUpdateSessionActive = false
        restoreWindowLevels()
    }

    private func registerObservers() {
        let center = NotificationCenter.default

        let windowNotifications: [Notification.Name] = [
            NSWindow.didBecomeMainNotification,
            NSWindow.didBecomeKeyNotification,
        ]
        windowObserverTokens = windowNotifications.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
                MainActor.assumeIsolated { [weak self] in
                    self?.handleWindowNotification(notification)
                }
            }
        }

        let appNotifications: [Notification.Name] = [
            NSApplication.didBecomeActiveNotification,
        ]
        appObserverTokens = appNotifications.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { [weak self] in
                    guard let self, self.isUpdateSessionActive else { return }
                    self.bringUpdatePopupToFront()
                }
            }
        }
    }

    private func handleWindowNotification(_ notification: Notification) {
        guard isUpdateSessionActive else {
            return
        }
        guard let window = notification.object as? NSWindow, isSparkleWindow(window) else {
            return
        }

        promoteWindow(window)
    }

    private func beginUpdateSession() {
        isUpdateSessionActive = true
        bringUpdatePopupToFront()
    }

    private func bringUpdatePopupToFront() {
        NSApp.activate(ignoringOtherApps: true)

        for window in NSApp.windows where window.isVisible && isSparkleWindow(window) {
            promoteWindow(window)
        }

        trackedWindows.removeAll { $0.window == nil }
    }

    private func promoteWindow(_ window: NSWindow) {
        if !trackedWindows.contains(where: { $0.window === window }) {
            trackedWindows.append(TrackedWindow(window: window, originalLevel: window.level))
        }

        window.level = .floating
        window.collectionBehavior.insert(.fullScreenAuxiliary)
        window.orderFrontRegardless()
    }

    private func restoreWindowLevels() {
        for trackedWindow in trackedWindows {
            guard let window = trackedWindow.window else { continue }
            window.level = trackedWindow.originalLevel
        }
        trackedWindows.removeAll()
    }

    private func isSparkleWindow(_ window: NSWindow) -> Bool {
        if let controller = window.windowController {
            let controllerClass = type(of: controller)
            let controllerBundleID = Bundle(for: controllerClass).bundleIdentifier ?? ""
            if controllerBundleID.localizedCaseInsensitiveContains("sparkle") {
                return true
            }
        }

        if let delegate = window.delegate {
            let delegateClass = type(of: delegate)
            let delegateBundleID = Bundle(for: delegateClass).bundleIdentifier ?? ""
            if delegateBundleID.localizedCaseInsensitiveContains("sparkle") {
                return true
            }
        }

        return false
    }
}
