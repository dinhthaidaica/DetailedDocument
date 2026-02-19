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
    case internationalTimes
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
        case .internationalTimes:
            return "Giờ quốc tế"
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
        case .internationalTimes:
            return "Giờ hiện tại ở các múi giờ chính"
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
        case .internationalTimes:
            return "globe"
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
        .internationalTimes,
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

struct InternationalTimeZonePreset: Identifiable, Hashable {
    let id: String
    let city: String
    let country: String
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
    static let defaultMenuBarPanelWidth: Double = 360
    static let defaultMenuBarPanelHeight: Double = 600
    static let menuBarPanelWidthRange: ClosedRange<Double> = 220 ... 760
    static let menuBarPanelHeightRange: ClosedRange<Double> = 320 ... 1200
    static let compactMenuBarPanelSize = CGSize(width: 340, height: 560)
    static let standardMenuBarPanelSize = CGSize(width: defaultMenuBarPanelWidth, height: defaultMenuBarPanelHeight)
    static let expandedMenuBarPanelSize = CGSize(width: 520, height: 860)
    static let availableInternationalTimeZones: [InternationalTimeZonePreset] = [
        InternationalTimeZonePreset(id: "Asia/Ho_Chi_Minh", city: "Hà Nội", country: "Việt Nam"),
        InternationalTimeZonePreset(id: "Asia/Bangkok", city: "Bangkok", country: "Thái Lan"),
        InternationalTimeZonePreset(id: "Asia/Singapore", city: "Singapore", country: "Singapore"),
        InternationalTimeZonePreset(id: "Asia/Hong_Kong", city: "Hồng Kông", country: "Trung Quốc"),
        InternationalTimeZonePreset(id: "Asia/Tokyo", city: "Tokyo", country: "Nhật Bản"),
        InternationalTimeZonePreset(id: "Asia/Seoul", city: "Seoul", country: "Hàn Quốc"),
        InternationalTimeZonePreset(id: "Australia/Sydney", city: "Sydney", country: "Úc"),
        InternationalTimeZonePreset(id: "Pacific/Auckland", city: "Auckland", country: "New Zealand"),
        InternationalTimeZonePreset(id: "Asia/Dubai", city: "Dubai", country: "UAE"),
        InternationalTimeZonePreset(id: "Asia/Kolkata", city: "Mumbai", country: "Ấn Độ"),
        InternationalTimeZonePreset(id: "Europe/London", city: "London", country: "Anh"),
        InternationalTimeZonePreset(id: "Europe/Paris", city: "Paris", country: "Pháp"),
        InternationalTimeZonePreset(id: "Europe/Berlin", city: "Berlin", country: "Đức"),
        InternationalTimeZonePreset(id: "America/New_York", city: "New York", country: "Mỹ"),
        InternationalTimeZonePreset(id: "America/Chicago", city: "Chicago", country: "Mỹ"),
        InternationalTimeZonePreset(id: "America/Denver", city: "Denver", country: "Mỹ"),
        InternationalTimeZonePreset(id: "America/Los_Angeles", city: "Los Angeles", country: "Mỹ"),
    ]
    static let defaultInternationalTimeZoneIDs: [String] = [
        "Asia/Ho_Chi_Minh",
        "Asia/Tokyo",
        "Australia/Sydney",
        "Europe/London",
        "America/New_York",
        "America/Los_Angeles",
    ]
    private static let smartRecommendationLimit = 6
    private static let smartRecommendationByRegionPrefix: [String: [String]] = [
        "Asia": [
            "Asia/Ho_Chi_Minh",
            "Asia/Tokyo",
            "Europe/London",
            "America/New_York",
            "America/Los_Angeles",
            "Australia/Sydney",
        ],
        "Europe": [
            "Europe/London",
            "Europe/Paris",
            "Asia/Ho_Chi_Minh",
            "America/New_York",
            "America/Los_Angeles",
            "Asia/Tokyo",
        ],
        "America": [
            "America/New_York",
            "America/Chicago",
            "America/Los_Angeles",
            "Europe/London",
            "Asia/Ho_Chi_Minh",
            "Asia/Tokyo",
        ],
        "Australia": [
            "Australia/Sydney",
            "Asia/Ho_Chi_Minh",
            "Asia/Tokyo",
            "Europe/London",
            "America/New_York",
            "America/Los_Angeles",
        ],
        "Pacific": [
            "Pacific/Auckland",
            "Australia/Sydney",
            "Asia/Ho_Chi_Minh",
            "Asia/Tokyo",
            "Europe/London",
            "America/Los_Angeles",
        ],
    ]
    private static let internationalTimeZoneByID = Dictionary(
        uniqueKeysWithValues: availableInternationalTimeZones.map { ($0.id, $0) }
    )
    private static let settingsBackupDirectoryName = "LunarV"
    private static let settingsBackupFileName = "settings-backup.plist"
    private static let legacyDefaultsSuites = [
        "phamhungtien.LunarV",
        "com.phamhungtien.phtv",
    ]
    private static let defaultSettingsValues: [String: Any] = [
        "settings.menuBar.displayPreset": MenuBarDisplayPreset.compact.rawValue,
        "settings.menuBar.customTemplate": "",
        "settings.menuBar.titleFontSize": AppSettings.defaultMenuBarTitleFontSize,
        "settings.menuBar.titleFontFamily": AppSettings.defaultMenuBarTitleFontFamily,
        "settings.menuBar.titleBold": AppSettings.defaultMenuBarTitleBold,
        "settings.menuBar.titleItalic": AppSettings.defaultMenuBarTitleItalic,
        "settings.menuBar.titleUnderline": AppSettings.defaultMenuBarTitleUnderline,
        "settings.menuBar.showLeadingIcon": true,
        "settings.menuBar.leadingIconSize": AppSettings.defaultMenuBarLeadingIconSize,
        "settings.panel.showHeroCard": true,
        "settings.panel.showCanChiSection": true,
        "settings.panel.showHolidaySection": true,
        "settings.panel.showInternationalTimesSection": true,
        "settings.panel.showMonthCalendar": true,
        "settings.panel.showAuspiciousHoursSection": true,
        "settings.panel.showDayGuidanceSection": true,
        "settings.panel.showDetailSection": true,
        "settings.panel.showDateConverter": true,
        "settings.panel.windowWidth": AppSettings.defaultMenuBarPanelWidth,
        "settings.panel.windowHeight": AppSettings.defaultMenuBarPanelHeight,
        "settings.panel.internationalTimeZoneIDs": AppSettings.serializedInternationalTimeZoneIDs(AppSettings.defaultInternationalTimeZoneIDs),
        "settings.panel.cardOrder": PanelCardKind.serialized(PanelCardKind.defaultOrder),
        "settings.window.keepSettingsOnTop": true,
        "settings.notifications.enableHolidayNotifications": false,
        "settings.notifications.holidayReminderLeadDays": 1,
        "settings.notifications.holidayReminderHour": 8,
        "settings.notifications.windowDays": 60,
    ]
    private var defaultsChangeCancellables: Set<AnyCancellable> = []
    private var isApplyingRecoveredSettings = false
    private var lastPersistedSettingsSnapshotData: Data?
    private var cachedPanelCardOrderRaw: String?
    private var cachedPanelCardOrder: [PanelCardKind] = PanelCardKind.defaultOrder
    private var cachedInternationalTimeZoneIDsRaw: String?
    private var cachedInternationalTimeZoneIDs: [String] = AppSettings.defaultInternationalTimeZoneIDs
    private var cachedSelectedInternationalTimeZonesIDs: [String] = AppSettings.defaultInternationalTimeZoneIDs
    private var cachedSelectedInternationalTimeZones: [InternationalTimeZonePreset] = AppSettings.defaultInternationalTimeZoneIDs.compactMap {
        AppSettings.internationalTimeZoneByID[$0]
    }

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
    @AppStorage("settings.panel.showInternationalTimesSection") var showInternationalTimesSection: Bool = true
    @AppStorage("settings.panel.showMonthCalendar") var showMonthCalendar: Bool = true
    @AppStorage("settings.panel.showAuspiciousHoursSection") var showAuspiciousHoursSection: Bool = true
    @AppStorage("settings.panel.showDayGuidanceSection") var showDayGuidanceSection: Bool = true
    @AppStorage("settings.panel.showDetailSection") var showDetailSection: Bool = true
    @AppStorage("settings.panel.showDateConverter") var showDateConverter: Bool = true
    @AppStorage("settings.panel.windowWidth") private var menuBarPanelWidthStorage: Double = AppSettings.defaultMenuBarPanelWidth
    @AppStorage("settings.panel.windowHeight") private var menuBarPanelHeightStorage: Double = AppSettings.defaultMenuBarPanelHeight
    @AppStorage("settings.panel.internationalTimeZoneIDs") private var internationalTimeZoneIDsRaw: String = AppSettings.serializedInternationalTimeZoneIDs(AppSettings.defaultInternationalTimeZoneIDs)
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
        normalizeMenuBarPanelSizeIfNeeded()
        normalizeInternationalTimeZoneIDsIfNeeded()
        normalizePanelCardOrderIfNeeded()
        persistForUpdateSafety()
        observeDefaultsChangesForUpdateSafety()
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
        if panelCardOrderRaw == cachedPanelCardOrderRaw {
            return cachedPanelCardOrder
        }

        let normalized = PanelCardKind.normalizedOrder(from: panelCardOrderRaw)
        cachedPanelCardOrderRaw = panelCardOrderRaw
        cachedPanelCardOrder = normalized
        return normalized
    }

    func movePanelCard(fromOffsets: IndexSet, toOffset: Int) {
        var nextOrder = panelCardOrder
        nextOrder.move(fromOffsets: fromOffsets, toOffset: toOffset)
        let nextRaw = PanelCardKind.serialized(nextOrder)
        panelCardOrderRaw = nextRaw
        cachedPanelCardOrderRaw = nextRaw
        cachedPanelCardOrder = nextOrder
    }

    func resetPanelCardOrder() {
        let defaultRaw = PanelCardKind.serialized(PanelCardKind.defaultOrder)
        panelCardOrderRaw = defaultRaw
        cachedPanelCardOrderRaw = defaultRaw
        cachedPanelCardOrder = PanelCardKind.defaultOrder
    }

    var menuBarPanelWidthValue: Double {
        Self.clampedMenuBarPanelWidth(menuBarPanelWidthStorage)
    }

    var menuBarPanelHeightValue: Double {
        Self.clampedMenuBarPanelHeight(menuBarPanelHeightStorage)
    }

    var menuBarPanelWidthCGFloat: CGFloat {
        CGFloat(menuBarPanelWidthValue)
    }

    var menuBarPanelHeightCGFloat: CGFloat {
        CGFloat(menuBarPanelHeightValue)
    }

    func setMenuBarPanelWidth(_ width: Double) {
        let clamped = Self.clampedMenuBarPanelWidth(width)
        guard clamped != menuBarPanelWidthStorage else {
            return
        }
        objectWillChange.send()
        menuBarPanelWidthStorage = clamped
    }

    func setMenuBarPanelHeight(_ height: Double) {
        let clamped = Self.clampedMenuBarPanelHeight(height)
        guard clamped != menuBarPanelHeightStorage else {
            return
        }
        objectWillChange.send()
        menuBarPanelHeightStorage = clamped
    }

    func setMenuBarPanelSize(width: Double, height: Double) {
        let clampedWidth = Self.clampedMenuBarPanelWidth(width)
        let clampedHeight = Self.clampedMenuBarPanelHeight(height)
        guard clampedWidth != menuBarPanelWidthStorage || clampedHeight != menuBarPanelHeightStorage else {
            return
        }
        objectWillChange.send()
        menuBarPanelWidthStorage = clampedWidth
        menuBarPanelHeightStorage = clampedHeight
    }

    func resetMenuBarPanelSize() {
        setMenuBarPanelSize(
            width: Self.defaultMenuBarPanelWidth,
            height: Self.defaultMenuBarPanelHeight
        )
    }

    var selectedInternationalTimeZoneIDs: [String] {
        if internationalTimeZoneIDsRaw == cachedInternationalTimeZoneIDsRaw {
            return cachedInternationalTimeZoneIDs
        }

        let normalized = Self.normalizedInternationalTimeZoneIDs(from: internationalTimeZoneIDsRaw)
        cachedInternationalTimeZoneIDsRaw = internationalTimeZoneIDsRaw
        cachedInternationalTimeZoneIDs = normalized
        return normalized
    }

    var selectedInternationalTimeZones: [InternationalTimeZonePreset] {
        let ids = selectedInternationalTimeZoneIDs
        if ids == cachedSelectedInternationalTimeZonesIDs {
            return cachedSelectedInternationalTimeZones
        }

        let mapped = ids.compactMap { Self.internationalTimeZoneByID[$0] }
        cachedSelectedInternationalTimeZonesIDs = ids
        cachedSelectedInternationalTimeZones = mapped
        return mapped
    }

    var smartRecommendedInternationalTimeZones: [InternationalTimeZonePreset] {
        let recommendedIDs = Self.smartRecommendedInternationalTimeZoneIDs(for: TimeZone.autoupdatingCurrent.identifier)
        return recommendedIDs.compactMap { Self.internationalTimeZoneByID[$0] }
    }

    func isInternationalTimeZoneSelected(_ preset: InternationalTimeZonePreset) -> Bool {
        selectedInternationalTimeZoneIDs.contains(preset.id)
    }

    func setInternationalTimeZoneSelected(_ isSelected: Bool, preset: InternationalTimeZonePreset) {
        var nextIDs = selectedInternationalTimeZoneIDs
        if isSelected {
            guard !nextIDs.contains(preset.id) else {
                return
            }
            nextIDs.append(preset.id)
        } else {
            guard nextIDs.contains(preset.id) else {
                return
            }
            nextIDs.removeAll { $0 == preset.id }
            guard !nextIDs.isEmpty else {
                return
            }
        }

        setInternationalTimeZoneIDs(nextIDs)
    }

    func moveInternationalTimeZone(fromOffsets: IndexSet, toOffset: Int) {
        var nextIDs = selectedInternationalTimeZoneIDs
        nextIDs.move(fromOffsets: fromOffsets, toOffset: toOffset)
        setInternationalTimeZoneIDs(nextIDs)
    }

    func sortInternationalTimeZonesByCity(ascending: Bool = true) {
        let orderedIDs = selectedInternationalTimeZones
            .sorted { lhs, rhs in
                let comparison = lhs.city.localizedCaseInsensitiveCompare(rhs.city)
                if comparison == .orderedSame {
                    return ascending ? lhs.id < rhs.id : lhs.id > rhs.id
                }
                return ascending ? comparison == .orderedAscending : comparison == .orderedDescending
            }
            .map(\.id)
        setInternationalTimeZoneIDs(orderedIDs)
    }

    func sortInternationalTimeZonesByUTCOffset(ascending: Bool = true, at date: Date = Date()) {
        let orderedIDs = selectedInternationalTimeZones
            .sorted { lhs, rhs in
                let lhsOffset = TimeZone(identifier: lhs.id)?.secondsFromGMT(for: date) ?? 0
                let rhsOffset = TimeZone(identifier: rhs.id)?.secondsFromGMT(for: date) ?? 0

                if lhsOffset == rhsOffset {
                    let comparison = lhs.city.localizedCaseInsensitiveCompare(rhs.city)
                    if comparison == .orderedSame {
                        return ascending ? lhs.id < rhs.id : lhs.id > rhs.id
                    }
                    return ascending ? comparison == .orderedAscending : comparison == .orderedDescending
                }

                return ascending ? lhsOffset < rhsOffset : lhsOffset > rhsOffset
            }
            .map(\.id)
        setInternationalTimeZoneIDs(orderedIDs)
    }

    func applySmartInternationalTimeZones() {
        let recommendedIDs = Self.smartRecommendedInternationalTimeZoneIDs(for: TimeZone.autoupdatingCurrent.identifier)
        setInternationalTimeZoneIDs(recommendedIDs)
    }

    func selectAllInternationalTimeZones() {
        let allIDs = Self.availableInternationalTimeZones.map(\.id)
        setInternationalTimeZoneIDs(allIDs)
    }

    func resetInternationalTimeZones() {
        setInternationalTimeZoneIDs(Self.defaultInternationalTimeZoneIDs)
    }

    private func setInternationalTimeZoneIDs(_ ids: [String]) {
        let normalizedIDs = Self.normalizedInternationalTimeZoneIDs(from: Self.serializedInternationalTimeZoneIDs(ids))
        let nextRaw = Self.serializedInternationalTimeZoneIDs(normalizedIDs)
        guard nextRaw != internationalTimeZoneIDsRaw else {
            return
        }

        objectWillChange.send()
        internationalTimeZoneIDsRaw = nextRaw
        cachedInternationalTimeZoneIDsRaw = nextRaw
        cachedInternationalTimeZoneIDs = normalizedIDs
        cachedSelectedInternationalTimeZonesIDs = normalizedIDs
        cachedSelectedInternationalTimeZones = normalizedIDs.compactMap { Self.internationalTimeZoneByID[$0] }
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
        case .internationalTimes:
            return showInternationalTimesSection
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
        case .internationalTimes:
            showInternationalTimesSection = isVisible
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
        showInternationalTimesSection = true
        showMonthCalendar = true
        showAuspiciousHoursSection = true
        showDayGuidanceSection = true
        showDetailSection = true
        showDateConverter = true
        resetMenuBarPanelSize()
        resetInternationalTimeZones()
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
            let data = try PropertyListSerialization.data(
                fromPropertyList: snapshot,
                format: .xml,
                options: 0
            )
            guard data != lastPersistedSettingsSnapshotData else {
                return
            }

            let backupURL = try Self.settingsBackupURL()
            try FileManager.default.createDirectory(
                at: backupURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: backupURL, options: .atomic)
            lastPersistedSettingsSnapshotData = data
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
        cachedPanelCardOrderRaw = normalized
        cachedPanelCardOrder = PanelCardKind.normalizedOrder(from: normalized)
    }

    private func normalizeInternationalTimeZoneIDsIfNeeded() {
        let normalizedIDs = Self.normalizedInternationalTimeZoneIDs(from: internationalTimeZoneIDsRaw)
        let normalizedRaw = Self.serializedInternationalTimeZoneIDs(normalizedIDs)
        guard normalizedRaw != internationalTimeZoneIDsRaw else {
            return
        }
        internationalTimeZoneIDsRaw = normalizedRaw
        cachedInternationalTimeZoneIDsRaw = normalizedRaw
        cachedInternationalTimeZoneIDs = normalizedIDs
        cachedSelectedInternationalTimeZonesIDs = normalizedIDs
        cachedSelectedInternationalTimeZones = normalizedIDs.compactMap { Self.internationalTimeZoneByID[$0] }
    }

    private func normalizeMenuBarPanelSizeIfNeeded() {
        let normalizedWidth = Self.clampedMenuBarPanelWidth(menuBarPanelWidthStorage)
        if normalizedWidth != menuBarPanelWidthStorage {
            menuBarPanelWidthStorage = normalizedWidth
        }

        let normalizedHeight = Self.clampedMenuBarPanelHeight(menuBarPanelHeightStorage)
        if normalizedHeight != menuBarPanelHeightStorage {
            menuBarPanelHeightStorage = normalizedHeight
        }
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

    private static func clampedMenuBarPanelWidth(_ value: Double) -> Double {
        round(min(max(value, menuBarPanelWidthRange.lowerBound), menuBarPanelWidthRange.upperBound))
    }

    private static func clampedMenuBarPanelHeight(_ value: Double) -> Double {
        round(min(max(value, menuBarPanelHeightRange.lowerBound), menuBarPanelHeightRange.upperBound))
    }

    private static func normalizedInternationalTimeZoneIDs(from rawValue: String) -> [String] {
        var normalized: [String] = []
        var seen = Set<String>()

        for rawID in rawValue.split(separator: ",").map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) }) {
            guard internationalTimeZoneByID[rawID] != nil, !seen.contains(rawID) else {
                continue
            }
            normalized.append(rawID)
            seen.insert(rawID)
        }

        return normalized.isEmpty ? defaultInternationalTimeZoneIDs : normalized
    }

    private static func serializedInternationalTimeZoneIDs(_ ids: [String]) -> String {
        ids.joined(separator: ",")
    }

    private static func smartRecommendedInternationalTimeZoneIDs(for localTimeZoneID: String) -> [String] {
        let prefix = localTimeZoneID.split(separator: "/").first.map(String.init) ?? ""

        var candidates: [String] = []
        if internationalTimeZoneByID[localTimeZoneID] != nil {
            candidates.append(localTimeZoneID)
        }
        if let regionBased = smartRecommendationByRegionPrefix[prefix] {
            candidates.append(contentsOf: regionBased)
        }
        candidates.append(contentsOf: defaultInternationalTimeZoneIDs)

        var recommended: [String] = []
        var seen = Set<String>()
        for id in candidates where internationalTimeZoneByID[id] != nil && !seen.contains(id) {
            recommended.append(id)
            seen.insert(id)
            if recommended.count >= smartRecommendationLimit {
                break
            }
        }

        return recommended.isEmpty ? defaultInternationalTimeZoneIDs : recommended
    }

    private func restoreSettingsFromBackupIfNeeded() {
        let defaults = UserDefaults.standard
        guard let recoverySnapshot = Self.loadRecoverySnapshot(), !recoverySnapshot.isEmpty else {
            return
        }

        isApplyingRecoveredSettings = true
        defer {
            isApplyingRecoveredSettings = false
        }

        var restoredCount = 0
        for (key, value) in recoverySnapshot where Self.shouldPersistSetting(key: key) {
            let currentValue = defaults.object(forKey: key)

            if key.hasPrefix("settings.") {
                guard currentValue == nil || Self.matchesDefaultSettingValue(currentValue, for: key) else {
                    continue
                }
            } else {
                guard currentValue == nil else {
                    continue
                }
            }

            defaults.set(value, forKey: key)
            restoredCount += 1
        }

        guard restoredCount > 0 else {
            return
        }

        _ = CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
        AppLogger.system.info("Recovered \(restoredCount) settings key(s) from upgrade snapshot")
    }

    private func observeDefaultsChangesForUpdateSafety() {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: UserDefaults.standard)
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, !self.isApplyingRecoveredSettings else {
                    return
                }
                self.persistForUpdateSafety()
            }
            .store(in: &defaultsChangeCancellables)
    }

    private static func settingsSnapshot(from dictionary: [String: Any]) -> [String: Any] {
        dictionary.filter { shouldPersistSetting(key: $0.key) }
    }

    private static func matchesDefaultSettingValue(_ value: Any?, for key: String) -> Bool {
        guard
            let value,
            let defaultValue = defaultSettingsValues[key],
            let lhs = value as? NSObject,
            let rhs = defaultValue as? NSObject
        else {
            return false
        }
        return lhs == rhs
    }

    private static func loadRecoverySnapshot() -> [String: Any]? {
        if
            let backupURL = try? settingsBackupURL(),
            let data = try? Data(contentsOf: backupURL),
            let propertyList = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
            let snapshot = propertyList as? [String: Any],
            !snapshot.isEmpty
        {
            return snapshot
        }

        for suiteName in legacyDefaultsSuites {
            guard
                let suiteDefaults = UserDefaults(suiteName: suiteName)
            else {
                continue
            }
            let snapshot = settingsSnapshot(from: suiteDefaults.dictionaryRepresentation())
            if !snapshot.isEmpty {
                return snapshot
            }
        }
        return nil
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
