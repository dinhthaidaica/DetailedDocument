import Foundation
import Combine

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var menuBarDisplayPreset: MenuBarDisplayPreset {
        didSet {
            defaults.set(menuBarDisplayPreset.rawValue, forKey: Keys.menuBarDisplayPreset)
        }
    }

    @Published var customMenuBarTemplate: String {
        didSet {
            defaults.set(customMenuBarTemplate, forKey: Keys.customMenuBarTemplate)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if
            let raw = defaults.string(forKey: Keys.menuBarDisplayPreset),
            let preset = MenuBarDisplayPreset(rawValue: raw)
        {
            menuBarDisplayPreset = preset
        } else {
            menuBarDisplayPreset = .compact
        }

        customMenuBarTemplate = defaults.string(forKey: Keys.customMenuBarTemplate) ?? ""
    }

    var resolvedMenuBarTemplate: String {
        MenuBarTitleFormatter.resolvedTemplate(
            preset: menuBarDisplayPreset,
            customTemplate: customMenuBarTemplate
        )
    }

    func resetMenuBarDisplaySettings() {
        menuBarDisplayPreset = .compact
        customMenuBarTemplate = ""
    }

    private enum Keys {
        static let menuBarDisplayPreset = "settings.menuBar.displayPreset"
        static let customMenuBarTemplate = "settings.menuBar.customTemplate"
    }
}
