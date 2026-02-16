//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import SwiftUI
import AppKit

@main
struct LunarVApp: App {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var viewModel = LunarMenuBarViewModel(settings: AppSettings.shared)
    @StateObject private var notificationManager = HolidayNotificationManager(settings: AppSettings.shared)

    private var menuBarTitleFontSizeCGFloat: CGFloat {
        settings.menuBarTitleFontSizeCGFloat
    }

    private var menuBarSystemFont: NSFont {
        NSFont.menuBarFont(ofSize: menuBarTitleFontSizeCGFloat)
    }

    private var menuBarLeadingIconRenderSize: CGFloat {
        let statusBarMax = max(NSStatusBar.system.thickness - 2, 10)
        return min(settings.menuBarLeadingIconSizeCGFloat, statusBarMax)
    }

    private var menuBarLabelIdentity: String {
        let title = viewModel.menuBarTitle
        let titleSize = settings.menuBarTitleFontSizeValue
        let iconVisibility = settings.showMenuBarLeadingIconValue ? 1 : 0
        let iconSize = settings.menuBarLeadingIconSizeValue
        return "\(title)|\(titleSize)|\(iconVisibility)|\(iconSize)"
    }

    private var menuBarLabelImage: NSImage? {
        let text = viewModel.menuBarTitle
        guard !text.isEmpty else {
            return nil
        }

        let font = menuBarSystemFont
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black,
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()

        let spacing: CGFloat = settings.showMenuBarLeadingIconValue ? AppSettings.menuBarIconTitleSpacing : 0
        let iconSize: CGFloat = settings.showMenuBarLeadingIconValue ? menuBarLeadingIconRenderSize : 0

        let width = ceil(iconSize + spacing + textSize.width)
        let height = ceil(max(iconSize, textSize.height))
        guard width > 0, height > 0 else {
            return nil
        }

        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()
        defer { image.unlockFocus() }

        if settings.showMenuBarLeadingIconValue, let icon = NSImage(named: "LunarVMenubar")?.copy() as? NSImage {
            icon.isTemplate = true
            let iconY = floor((height - iconSize) / 2)
            icon.draw(
                in: NSRect(x: 0, y: iconY, width: iconSize, height: iconSize),
                from: .zero,
                operation: .sourceOver,
                fraction: 1
            )
        }

        let textX = iconSize + spacing
        let textY = floor((height - textSize.height) / 2)
        attributedText.draw(at: NSPoint(x: textX, y: textY))

        image.isTemplate = true
        return image
    }

    var body: some Scene {
        MenuBarExtra {
            LunarMenuBarView(viewModel: viewModel)
        } label: {
            Group {
                if let menuBarLabelImage {
                    Image(nsImage: menuBarLabelImage)
                } else {
                    Text(viewModel.menuBarTitle)
                        .font(Font(menuBarSystemFont))
                }
            }
            .id(menuBarLabelIdentity)
        }
        .menuBarExtraStyle(.window)
        .commands {
            LunarVCommands()
        }

        Window("", id: "settings") {
            AppSettingsView()
                .environmentObject(settings)
                .environmentObject(notificationManager)
        }
        .defaultSize(width: 820, height: 600)
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .restorationBehavior(.disabled)
    }
}

private struct LunarVCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Cài đặt...") {
                openWindow(id: "settings")
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}
