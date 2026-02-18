//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import SwiftUI
import AppKit
import Sparkle

@main
struct LunarVApp: App {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var viewModel = LunarMenuBarViewModel(settings: AppSettings.shared)
    @StateObject private var notificationManager = HolidayNotificationManager(settings: AppSettings.shared)
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    private var menuBarTitleFontSizeCGFloat: CGFloat {
        settings.menuBarTitleFontSizeCGFloat
    }

    private var menuBarTitleFont: NSFont {
        MenuBarFontResolver.resolve(
            family: settings.menuBarTitleFontFamilyValue,
            size: menuBarTitleFontSizeCGFloat,
            bold: settings.menuBarTitleBoldValue,
            italic: settings.menuBarTitleItalicValue
        )
    }

    private var menuBarLeadingIconRenderSize: CGFloat {
        let statusBarMax = max(NSStatusBar.system.thickness - 2, 10)
        return min(settings.menuBarLeadingIconSizeCGFloat, statusBarMax)
    }

    private var menuBarLabelIdentity: String {
        let title = viewModel.menuBarTitle
        let sizingTitle = viewModel.menuBarTitleSizingText
        let titleSize = settings.menuBarTitleFontSizeValue
        let titleFamily = settings.menuBarTitleFontFamilyValue
        let titleBold = settings.menuBarTitleBoldValue ? 1 : 0
        let titleItalic = settings.menuBarTitleItalicValue ? 1 : 0
        let titleUnderline = settings.menuBarTitleUnderlineValue ? 1 : 0
        let iconVisibility = settings.showMenuBarLeadingIconValue ? 1 : 0
        let iconSize = settings.menuBarLeadingIconSizeValue
        return "\(title)|\(sizingTitle)|\(titleSize)|\(titleFamily)|\(titleBold)|\(titleItalic)|\(titleUnderline)|\(iconVisibility)|\(iconSize)"
    }

    private var menuBarLabelImage: NSImage? {
        let text = viewModel.menuBarTitle
        let sizingText = viewModel.menuBarTitleSizingText
        guard !text.isEmpty else {
            return nil
        }

        let font = menuBarTitleFont
        var attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black,
        ]
        if settings.menuBarTitleUnderlineValue {
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedText.size()
        let sizingSample = sizingText.isEmpty ? text : sizingText
        let sizingAttributedText = NSAttributedString(string: sizingSample, attributes: attributes)
        let sizingTextSize = sizingAttributedText.size()

        let spacing: CGFloat = settings.showMenuBarLeadingIconValue ? AppSettings.menuBarIconTitleSpacing : 0
        let iconSize: CGFloat = settings.showMenuBarLeadingIconValue ? menuBarLeadingIconRenderSize : 0

        let width = ceil(iconSize + spacing + max(textSize.width, sizingTextSize.width))
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
                        .font(Font(menuBarTitleFont))
                        .underline(settings.menuBarTitleUnderlineValue)
                }
            }
            .id(menuBarLabelIdentity)
        }
        .menuBarExtraStyle(.window)
        .commands {
            LunarVCommands(updater: updaterController.updater)
        }

        Window("", id: "settings") {
            AppSettingsView(updater: updaterController.updater)
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
    let updater: SPUUpdater
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Cài đặt...") {
                openWindow(id: "settings")
            }
            .keyboardShortcut(",", modifiers: .command)
        }

        CommandGroup(after: .appInfo) {
            CheckForUpdatesView(updater: updater)
        }
    }
}
