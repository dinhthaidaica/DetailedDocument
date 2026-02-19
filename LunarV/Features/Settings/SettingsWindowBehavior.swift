//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit
import SwiftUI

final class SettingsWindowObserverView: NSView {
    var onWindowChanged: ((NSWindow?) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        onWindowChanged?(window)
    }
}

struct SettingsWindowBehavior: NSViewRepresentable {
    let keepOnTop: Bool
    private static let fixedWindowSize = NSSize(width: 820, height: 600)

    final class Coordinator {
        weak var trackedWindow: NSWindow?
        var hasAppliedBaseConfiguration = false
        var lastAppliedKeepOnTop: Bool?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> SettingsWindowObserverView {
        let view = SettingsWindowObserverView(frame: .zero)
        view.onWindowChanged = { window in
            Self.configure(window, keepOnTop: keepOnTop, coordinator: context.coordinator)
        }
        return view
    }

    func updateNSView(_ nsView: SettingsWindowObserverView, context: Context) {
        nsView.onWindowChanged = { window in
            Self.configure(window, keepOnTop: keepOnTop, coordinator: context.coordinator)
        }
        Self.configure(nsView.window, keepOnTop: keepOnTop, coordinator: context.coordinator)
    }

    private static func configure(_ window: NSWindow?, keepOnTop: Bool, coordinator: Coordinator) {
        guard let window else { return }

        if coordinator.trackedWindow !== window {
            coordinator.trackedWindow = window
            coordinator.hasAppliedBaseConfiguration = false
            coordinator.lastAppliedKeepOnTop = nil
        }

        if !coordinator.hasAppliedBaseConfiguration {
            window.minSize = fixedWindowSize
            window.maxSize = fixedWindowSize
            window.styleMask.remove(.resizable)
            window.collectionBehavior.remove(.fullScreenPrimary)
            window.collectionBehavior.remove(.fullScreenAuxiliary)
            window.standardWindowButton(.zoomButton)?.isEnabled = false

            window.identifier = NSUserInterfaceItemIdentifier("settings.lunarv")
            window.isMovableByWindowBackground = true
            window.collectionBehavior.insert(.moveToActiveSpace)
            coordinator.hasAppliedBaseConfiguration = true

            // Defer bring-to-front until current layout pass is done to avoid
            // reentrant NSHostingView layout warnings.
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                window.makeKeyAndOrderFront(nil)
            }
        }

        if coordinator.lastAppliedKeepOnTop != keepOnTop {
            window.level = keepOnTop ? .floating : .normal
            coordinator.lastAppliedKeepOnTop = keepOnTop
        }
    }
}
