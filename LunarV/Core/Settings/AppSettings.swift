//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import SwiftUI
import Combine

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // MARK: - Menu Bar Display
    @AppStorage("settings.menuBar.displayPreset") var menuBarDisplayPreset: MenuBarDisplayPreset = .compact
    @AppStorage("settings.menuBar.customTemplate") var customMenuBarTemplate: String = ""

    // MARK: - Panel Sections Visibility
    @AppStorage("settings.panel.showHeroCard") var showHeroCard: Bool = true
    @AppStorage("settings.panel.showCanChiSection") var showCanChiSection: Bool = true
    @AppStorage("settings.panel.showHolidaySection") var showHolidaySection: Bool = true
    @AppStorage("settings.panel.showMonthCalendar") var showMonthCalendar: Bool = true
    @AppStorage("settings.panel.showDetailSection") var showDetailSection: Bool = true

    // MARK: - Appearance
    @AppStorage("settings.appearance.customAccentColor") var customAccentColor: Color = .blue

    // MARK: - Window Behavior
    @AppStorage("settings.window.keepSettingsOnTop") var keepSettingsOnTop: Bool = true

    private init() {}

    func resetMenuBarDisplaySettings() {
        menuBarDisplayPreset = .compact
        customMenuBarTemplate = ""
    }
    
    func resetAllSettings() {
        resetMenuBarDisplaySettings()
        showHeroCard = true
        showCanChiSection = true
        showHolidaySection = true
        showMonthCalendar = true
        showDetailSection = true
        customAccentColor = .blue
    }
}

// MARK: - Color Persistence
extension Color: @retroactive RawRepresentable {
    public init?(rawValue: String) {
        guard let data = Data(base64Encoded: rawValue) else { return nil }
        do {
            if let nsColor = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) {
                self = Color(nsColor: nsColor)
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }

    public var rawValue: String {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: NSColor(self), requiringSecureCoding: false)
            return data.base64EncodedString()
        } catch {
            return ""
        }
    }
}
