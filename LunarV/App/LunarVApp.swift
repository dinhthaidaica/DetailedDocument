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

    private var menuBarTitleFont: NSFont {
        resolvedMenuBarFont(size: menuBarTitleFontSizeCGFloat)
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

private extension LunarVApp {
    func resolvedMenuBarFont(size: CGFloat) -> NSFont {
        let desiredFamily = settings.menuBarTitleFontFamilyValue
        let traits = settings.menuBarTitleItalicValue ? NSFontTraitMask.italicFontMask : []
        let weight = settings.menuBarTitleBoldValue ? 9 : 5

        if !desiredFamily.isEmpty,
           let custom = NSFontManager.shared.font(
               withFamily: desiredFamily,
               traits: traits,
               weight: weight,
               size: size
           ) {
            return custom
        }

        let base = NSFont.menuBarFont(ofSize: size)
        let descriptorTraits = resolvedSymbolicTraits(for: base.fontDescriptor.symbolicTraits)
        let descriptor = base.fontDescriptor.withSymbolicTraits(descriptorTraits)
        if let resolved = NSFont(descriptor: descriptor, size: size) {
            return resolved
        }
        return base
    }

    func resolvedSymbolicTraits(for current: NSFontDescriptor.SymbolicTraits) -> NSFontDescriptor.SymbolicTraits {
        var traits = current
        if settings.menuBarTitleBoldValue {
            traits.insert(.bold)
        } else {
            traits.remove(.bold)
        }
        if settings.menuBarTitleItalicValue {
            traits.insert(.italic)
        } else {
            traits.remove(.italic)
        }
        return traits
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
