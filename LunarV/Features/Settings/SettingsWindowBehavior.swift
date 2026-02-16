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

        // Cập nhật level cửa sổ mỗi khi setting thay đổi hoặc cửa sổ mới được gán
        window.level = keepOnTop ? .floating : .normal

        if coordinator.trackedWindow !== window {
            coordinator.trackedWindow = window
            window.collectionBehavior.insert(.moveToActiveSpace)
            window.collectionBehavior.insert(.fullScreenAuxiliary)
            
            // Chỉ thực hiện focus/order front khi cửa sổ lần đầu xuất hiện
            NSApp.activate(ignoringOtherApps: true)
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
        }
    }
}
