//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import SwiftUI
import Combine
import os

enum PanelCardKind: String, CaseIterable, Identifiable, Hashable {
    case hero
    case canChi
    case auspiciousHours
    case dayGuidance
    case holidays
    case monthCalendar
    case dateConverter
    case detail

    var id: String { rawValue }

    var title: String {
        switch self {
        case .hero:
            return "Thẻ ngày hôm nay"
        case .canChi:
            return "Can chi & Con giáp"
        case .auspiciousHours:
            return "Giờ hoàng đạo"
        case .dayGuidance:
            return "Gợi ý trong ngày"
        case .holidays:
            return "Sự kiện sắp tới"
        case .monthCalendar:
            return "Lịch tháng"
        case .dateConverter:
            return "Chuyển đổi nhanh"
        case .detail:
            return "Thông tin khác"
        }
    }

    var subtitle: String {
        switch self {
        case .hero:
            return "Ngày âm lịch chính và tiết khí"
        case .canChi:
            return "Can chi ngày/tháng/năm"
        case .auspiciousHours:
            return "Khung giờ đẹp và hắc đạo"
        case .dayGuidance:
            return "Điểm ngày và gợi ý hoạt động"
        case .holidays:
            return "Các ngày lễ sắp tới"
        case .monthCalendar:
            return "Lưới tháng dương - âm"
        case .dateConverter:
            return "Đổi ngày âm / dương"
        case .detail:
            return "Thông tin bổ sung theo ngày"
        }
    }

    var icon: String {
        switch self {
        case .hero:
            return "sparkles"
        case .canChi:
            return "text.badge.checkmark"
        case .auspiciousHours:
            return "clock.badge.checkmark"
        case .dayGuidance:
            return "list.star"
        case .holidays:
            return "calendar.badge.clock"
        case .monthCalendar:
            return "calendar"
        case .dateConverter:
            return "arrow.left.arrow.right.circle"
        case .detail:
            return "info.bubble"
        }
    }

    static let defaultOrder: [PanelCardKind] = [
        .hero,
        .canChi,
        .auspiciousHours,
        .dayGuidance,
        .holidays,
        .monthCalendar,
        .dateConverter,
        .detail,
    ]

    static func serialized(_ order: [PanelCardKind]) -> String {
        order.map(\.rawValue).joined(separator: ",")
    }

    static func normalizedOrder(from rawValue: String) -> [PanelCardKind] {
        var uniqueOrder: [PanelCardKind] = []
        var seen = Set<PanelCardKind>()

        for component in rawValue.split(separator: ",") {
            guard
                let card = PanelCardKind(rawValue: String(component)),
                !seen.contains(card)
            else {
                continue
            }
            uniqueOrder.append(card)
            seen.insert(card)
        }

        for card in defaultOrder where !seen.contains(card) {
            uniqueOrder.append(card)
        }

        return uniqueOrder
    }
}

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()
    static let defaultMenuBarTitleFontSize: Double = 12
    static let menuBarTitleFontSizeRange: ClosedRange<Double> = 11 ... 16
    static let defaultMenuBarTitleFontFamily: String = ""
    static let defaultMenuBarTitleBold: Bool = false
    static let defaultMenuBarTitleItalic: Bool = false
    static let defaultMenuBarTitleUnderline: Bool = false
    static let defaultMenuBarLeadingIconSize: Double = 14
    static let menuBarLeadingIconSizeRange: ClosedRange<Double> = 10 ... 18
    static let menuBarIconTitleSpacing: CGFloat = 4
    private static let settingsBackupDirectoryName = "LunarV"
    private static let settingsBackupFileName = "settings-backup.plist"

    // MARK: - Menu Bar Display
    @AppStorage("settings.menuBar.displayPreset") var menuBarDisplayPreset: MenuBarDisplayPreset = .compact
    @AppStorage("settings.menuBar.customTemplate") var customMenuBarTemplate: String = ""
    @AppStorage("settings.menuBar.titleFontSize") private var menuBarTitleFontSizeStorage: Double = AppSettings.defaultMenuBarTitleFontSize
    @AppStorage("settings.menuBar.titleFontFamily") private var menuBarTitleFontFamilyStorage: String = AppSettings.defaultMenuBarTitleFontFamily
    @AppStorage("settings.menuBar.titleBold") private var menuBarTitleBoldStorage: Bool = AppSettings.defaultMenuBarTitleBold
    @AppStorage("settings.menuBar.titleItalic") private var menuBarTitleItalicStorage: Bool = AppSettings.defaultMenuBarTitleItalic
    @AppStorage("settings.menuBar.titleUnderline") private var menuBarTitleUnderlineStorage: Bool = AppSettings.defaultMenuBarTitleUnderline
    @AppStorage("settings.menuBar.showLeadingIcon") private var showMenuBarLeadingIconStorage: Bool = true
    @AppStorage("settings.menuBar.leadingIconSize") private var menuBarLeadingIconSizeStorage: Double = AppSettings.defaultMenuBarLeadingIconSize

    // MARK: - Panel Sections Visibility
    @AppStorage("settings.panel.showHeroCard") var showHeroCard: Bool = true
    @AppStorage("settings.panel.showCanChiSection") var showCanChiSection: Bool = true
    @AppStorage("settings.panel.showHolidaySection") var showHolidaySection: Bool = true
    @AppStorage("settings.panel.showMonthCalendar") var showMonthCalendar: Bool = true
    @AppStorage("settings.panel.showAuspiciousHoursSection") var showAuspiciousHoursSection: Bool = true
    @AppStorage("settings.panel.showDayGuidanceSection") var showDayGuidanceSection: Bool = true
    @AppStorage("settings.panel.showDetailSection") var showDetailSection: Bool = true
    @AppStorage("settings.panel.showDateConverter") var showDateConverter: Bool = true
    @AppStorage("settings.panel.cardOrder") private var panelCardOrderRaw: String = PanelCardKind.serialized(PanelCardKind.defaultOrder)

    // MARK: - Window Behavior
    @AppStorage("settings.window.keepSettingsOnTop") var keepSettingsOnTop: Bool = true

    // MARK: - Notifications
    @AppStorage("settings.notifications.enableHolidayNotifications") var enableHolidayNotifications: Bool = false
    @AppStorage("settings.notifications.holidayReminderLeadDays") var holidayReminderLeadDays: Int = 1
    @AppStorage("settings.notifications.holidayReminderHour") var holidayReminderHour: Int = 8
    @AppStorage("settings.notifications.windowDays") var notificationWindowDays: Int = 60

    private init() {
        restoreSettingsFromBackupIfNeeded()
        normalizeMenuBarTitleFontSizeIfNeeded()
        normalizeMenuBarTitleFontFamilyIfNeeded()
        normalizeMenuBarLeadingIconSizeIfNeeded()
        normalizePanelCardOrderIfNeeded()
        persistForUpdateSafety()
    }

    var menuBarTitleFontSizeValue: Double {
        Self.clampedMenuBarTitleFontSize(menuBarTitleFontSizeStorage)
    }

    var menuBarTitleFontSizeCGFloat: CGFloat {
        CGFloat(menuBarTitleFontSizeValue)
    }

    func setMenuBarTitleFontSize(_ size: Double) {
        let clamped = Self.clampedMenuBarTitleFontSize(size)
        guard clamped != menuBarTitleFontSizeStorage else {
            return
        }
        objectWillChange.send()
        menuBarTitleFontSizeStorage = clamped
    }

    var menuBarTitleFontFamilyValue: String {
        menuBarTitleFontFamilyStorage.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func setMenuBarTitleFontFamily(_ family: String) {
        let normalized = family.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized != menuBarTitleFontFamilyStorage else {
            return
        }
        objectWillChange.send()
        menuBarTitleFontFamilyStorage = normalized
    }

    var menuBarTitleBoldValue: Bool {
        menuBarTitleBoldStorage
    }

    func setMenuBarTitleBold(_ isEnabled: Bool) {
        guard isEnabled != menuBarTitleBoldStorage else {
            return
        }
        objectWillChange.send()
        menuBarTitleBoldStorage = isEnabled
    }

    var menuBarTitleItalicValue: Bool {
        menuBarTitleItalicStorage
    }

    func setMenuBarTitleItalic(_ isEnabled: Bool) {
        guard isEnabled != menuBarTitleItalicStorage else {
            return
        }
        objectWillChange.send()
        menuBarTitleItalicStorage = isEnabled
    }

    var menuBarTitleUnderlineValue: Bool {
        menuBarTitleUnderlineStorage
    }

    func setMenuBarTitleUnderline(_ isEnabled: Bool) {
        guard isEnabled != menuBarTitleUnderlineStorage else {
            return
        }
        objectWillChange.send()
        menuBarTitleUnderlineStorage = isEnabled
    }

    var showMenuBarLeadingIconValue: Bool {
        showMenuBarLeadingIconStorage
    }

    func setShowMenuBarLeadingIcon(_ isVisible: Bool) {
        guard isVisible != showMenuBarLeadingIconStorage else {
            return
        }
        objectWillChange.send()
        showMenuBarLeadingIconStorage = isVisible
    }

    var menuBarLeadingIconSizeValue: Double {
        Self.clampedMenuBarLeadingIconSize(menuBarLeadingIconSizeStorage)
    }

    var menuBarLeadingIconSizeCGFloat: CGFloat {
        CGFloat(menuBarLeadingIconSizeValue)
    }

    func setMenuBarLeadingIconSize(_ size: Double) {
        let clamped = Self.clampedMenuBarLeadingIconSize(size)
        guard clamped != menuBarLeadingIconSizeStorage else {
            return
        }
        objectWillChange.send()
        menuBarLeadingIconSizeStorage = clamped
    }

    var panelCardOrder: [PanelCardKind] {
        PanelCardKind.normalizedOrder(from: panelCardOrderRaw)
    }

    func movePanelCard(fromOffsets: IndexSet, toOffset: Int) {
        var nextOrder = panelCardOrder
        nextOrder.move(fromOffsets: fromOffsets, toOffset: toOffset)
        panelCardOrderRaw = PanelCardKind.serialized(nextOrder)
    }

    func resetPanelCardOrder() {
        panelCardOrderRaw = PanelCardKind.serialized(PanelCardKind.defaultOrder)
    }

    func isPanelCardVisible(_ card: PanelCardKind) -> Bool {
        switch card {
        case .hero:
            return showHeroCard
        case .canChi:
            return showCanChiSection
        case .auspiciousHours:
            return showAuspiciousHoursSection
        case .dayGuidance:
            return showDayGuidanceSection
        case .holidays:
            return showHolidaySection
        case .monthCalendar:
            return showMonthCalendar
        case .dateConverter:
            return showDateConverter
        case .detail:
            return showDetailSection
        }
    }

    func setPanelCardVisible(_ isVisible: Bool, for card: PanelCardKind) {
        switch card {
        case .hero:
            showHeroCard = isVisible
        case .canChi:
            showCanChiSection = isVisible
        case .auspiciousHours:
            showAuspiciousHoursSection = isVisible
        case .dayGuidance:
            showDayGuidanceSection = isVisible
        case .holidays:
            showHolidaySection = isVisible
        case .monthCalendar:
            showMonthCalendar = isVisible
        case .dateConverter:
            showDateConverter = isVisible
        case .detail:
            showDetailSection = isVisible
        }
    }

    func resetMenuBarDisplaySettings() {
        menuBarDisplayPreset = .compact
        customMenuBarTemplate = ""
        setMenuBarTitleFontSize(Self.defaultMenuBarTitleFontSize)
        setMenuBarTitleFontFamily(Self.defaultMenuBarTitleFontFamily)
        setMenuBarTitleBold(Self.defaultMenuBarTitleBold)
        setMenuBarTitleItalic(Self.defaultMenuBarTitleItalic)
        setMenuBarTitleUnderline(Self.defaultMenuBarTitleUnderline)
        setShowMenuBarLeadingIcon(true)
        setMenuBarLeadingIconSize(Self.defaultMenuBarLeadingIconSize)
    }
    
    func resetAllSettings() {
        resetMenuBarDisplaySettings()
        showHeroCard = true
        showCanChiSection = true
        showHolidaySection = true
        showMonthCalendar = true
        showAuspiciousHoursSection = true
        showDayGuidanceSection = true
        showDetailSection = true
        showDateConverter = true
        resetPanelCardOrder()
        enableHolidayNotifications = false
        holidayReminderLeadDays = 1
        holidayReminderHour = 8
        notificationWindowDays = 60
        persistForUpdateSafety()
    }

    func persistForUpdateSafety() {
        let defaults = UserDefaults.standard
        let snapshot = Self.settingsSnapshot(from: defaults.dictionaryRepresentation())
        guard !snapshot.isEmpty else {
            return
        }

        do {
            let backupURL = try Self.settingsBackupURL()
            try FileManager.default.createDirectory(
                at: backupURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try PropertyListSerialization.data(
                fromPropertyList: snapshot,
                format: .xml,
                options: 0
            )
            try data.write(to: backupURL, options: .atomic)
            _ = CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
        } catch {
            AppLogger.system.error("Failed to backup settings before update: \(error.localizedDescription)")
        }
    }

    private func normalizePanelCardOrderIfNeeded() {
        let normalized = PanelCardKind.serialized(panelCardOrder)
        guard normalized != panelCardOrderRaw else {
            return
        }
        panelCardOrderRaw = normalized
    }

    private func normalizeMenuBarTitleFontSizeIfNeeded() {
        let normalized = Self.clampedMenuBarTitleFontSize(menuBarTitleFontSizeStorage)
        guard normalized != menuBarTitleFontSizeStorage else {
            return
        }
        menuBarTitleFontSizeStorage = normalized
    }

    private func normalizeMenuBarTitleFontFamilyIfNeeded() {
        let normalized = menuBarTitleFontFamilyStorage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized != menuBarTitleFontFamilyStorage else {
            return
        }
        menuBarTitleFontFamilyStorage = normalized
    }

    private func normalizeMenuBarLeadingIconSizeIfNeeded() {
        let normalized = Self.clampedMenuBarLeadingIconSize(menuBarLeadingIconSizeStorage)
        guard normalized != menuBarLeadingIconSizeStorage else {
            return
        }
        menuBarLeadingIconSizeStorage = normalized
    }

    private static func clampedMenuBarTitleFontSize(_ value: Double) -> Double {
        min(max(value, menuBarTitleFontSizeRange.lowerBound), menuBarTitleFontSizeRange.upperBound)
    }

    private static func clampedMenuBarLeadingIconSize(_ value: Double) -> Double {
        min(max(value, menuBarLeadingIconSizeRange.lowerBound), menuBarLeadingIconSizeRange.upperBound)
    }

    private func restoreSettingsFromBackupIfNeeded() {
        let defaults = UserDefaults.standard
        let currentSnapshot = Self.settingsSnapshot(from: defaults.dictionaryRepresentation())
        guard currentSnapshot.isEmpty else {
            return
        }

        guard
            let backupURL = try? Self.settingsBackupURL(),
            let data = try? Data(contentsOf: backupURL),
            let propertyList = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
            let backupSnapshot = propertyList as? [String: Any],
            !backupSnapshot.isEmpty
        else {
            return
        }

        for (key, value) in backupSnapshot where Self.shouldPersistSetting(key: key) {
            defaults.set(value, forKey: key)
        }
        _ = CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
        AppLogger.system.info("Restored settings from upgrade backup")
    }

    private static func settingsSnapshot(from dictionary: [String: Any]) -> [String: Any] {
        dictionary.filter { shouldPersistSetting(key: $0.key) }
    }

    private static func shouldPersistSetting(key: String) -> Bool {
        key.hasPrefix("settings.") || key.hasPrefix("SU")
    }

    private static func settingsBackupURL() throws -> URL {
        let appSupportURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return appSupportURL
            .appendingPathComponent(settingsBackupDirectoryName, isDirectory: true)
            .appendingPathComponent(settingsBackupFileName)
    }
}
