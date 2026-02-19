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

        window.minSize = fixedWindowSize
        window.maxSize = fixedWindowSize
        window.styleMask.remove(.resizable)
        window.collectionBehavior.remove(.fullScreenPrimary)
        window.collectionBehavior.remove(.fullScreenAuxiliary)
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.level = keepOnTop ? .floating : .normal

        if coordinator.trackedWindow !== window {
            coordinator.trackedWindow = window
            window.identifier = NSUserInterfaceItemIdentifier("settings.lunarv")
            window.isMovableByWindowBackground = true
            window.collectionBehavior.insert(.moveToActiveSpace)

            NSApp.activate(ignoringOtherApps: true)
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
        }

        constrainSplitViewSidebar(in: window.contentView)
    }

    private static let sidebarMinThickness: CGFloat = 230
    private static let sidebarMaxThickness: CGFloat = 320
    private static let detailMinThickness: CGFloat = 400

    /// Tìm NSSplitView và đặt hard constraint cho sidebar + detail để tránh layout vỡ khi kéo.
    private static func constrainSplitViewSidebar(in view: NSView?) {
        guard let view else { return }

        if let splitView = view as? NSSplitView,
           let splitController = splitView.delegate as? NSSplitViewController {
            let items = splitController.splitViewItems
            if let sidebarItem = items.first {
                sidebarItem.canCollapse = false
                sidebarItem.minimumThickness = sidebarMinThickness
                sidebarItem.maximumThickness = sidebarMaxThickness
            }
            if items.count > 1 {
                items[1].canCollapse = false
                items[1].minimumThickness = detailMinThickness
            }
            return
        }

        for subview in view.subviews {
            constrainSplitViewSidebar(in: subview)
        }
    }
}
