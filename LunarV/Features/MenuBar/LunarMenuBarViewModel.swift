//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit
import Combine
import Foundation
import os

@MainActor
final class LunarMenuBarViewModel: ObservableObject {
    @Published private(set) var menuBarTitle = "--/-- ÂL"
    @Published private(set) var menuBarTitleSizingText = "--/-- ÂL"
    @Published private(set) var info = LunarMenuBarInfo.placeholder
    @Published private(set) var viewingDate: Date
    
    // Xuất bản settings để View có thể quan sát
    @Published var settings: AppSettings

    private struct YearMonth: Hashable {
        let year: Int
        let month: Int
    }

    private struct RefreshSettings: Equatable {
        let displayPreset: MenuBarDisplayPreset
        let customTemplate: String
        let showInternationalTimesSection: Bool
        let selectedInternationalTimeZoneIDs: [String]
        let panelWidth: Double
        let panelHeight: Double

        init(settings: AppSettings) {
            displayPreset = settings.menuBarDisplayPreset
            customTemplate = settings.customMenuBarTemplate
            showInternationalTimesSection = settings.showInternationalTimesSection
            selectedInternationalTimeZoneIDs = settings.selectedInternationalTimeZoneIDs
            panelWidth = settings.menuBarPanelWidthValue
            panelHeight = settings.menuBarPanelHeightValue
        }
    }

    private static let maxCachedMonths = 24
    private static let internationalClockLocale = Locale(identifier: "vi_VN")
    private static var internationalClockTimeFormatterByTimeZoneID: [String: DateFormatter] = [:]
    private static var internationalClockWeekdayFormatterByTimeZoneID: [String: DateFormatter] = [:]
    private static var internationalCalendarByTimeZoneID: [String: Calendar] = [:]

    private let solarCalendar: Calendar
    private let lunarService: VietnameseLunarDateService
    private var refreshTask: Task<Void, Never>?
    private var systemNotificationObservers: [NSObjectProtocol] = []
    private var workspaceNotificationObservers: [NSObjectProtocol] = []
    private var settingsCancellables = Set<AnyCancellable>()
    private var monthCellsCache: [YearMonth: [LunarMonthDayCell]] = [:]
    private var monthCellsCacheOrder: [YearMonth] = []
    private var cachedUpcomingHolidays: [LunarHoliday] = []
    private var cachedUpcomingHolidaysAnchor: Date?
    private var lastInfoRefreshMinuteBucket: Int?
    private var lastObservedRefreshSettings: RefreshSettings

    init(
        lunarService: VietnameseLunarDateService? = nil,
        settings: AppSettings? = nil
    ) {
        let targetLunarService = lunarService ?? VietnameseLunarDateService()
        self.lunarService = targetLunarService
        self.solarCalendar = targetLunarService.calendar
        
        let targetSettings = settings ?? AppSettings.shared
        self.settings = targetSettings
        self.viewingDate = Date()
        self.lastObservedRefreshSettings = RefreshSettings(settings: targetSettings)

        startObservingSettings()
        startObservingSystemChanges()
        refresh(forceInfo: true)
    }

    deinit {
        refreshTask?.cancel()

        systemNotificationObservers.forEach { observer in
            NotificationCenter.default.removeObserver(observer)
        }

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceNotificationObservers.forEach { observer in
            workspaceCenter.removeObserver(observer)
        }
    }

    func refresh(forceInfo: Bool = false) {
        let now = Date()
        updateMenuBarTitle(now: now)
        if forceInfo || shouldRefreshInfo(at: now) {
            updateInfo(now: now, viewingDate: viewingDate)
            markInfoRefreshed(at: now)
        }
        scheduleRefresh(from: now)
    }

    func invalidateCaches() {
        monthCellsCache.removeAll()
        monthCellsCacheOrder.removeAll()
        cachedUpcomingHolidaysAnchor = nil
        lastInfoRefreshMinuteBucket = nil
    }

    func nextMonth() {
        if let next = solarCalendar.date(byAdding: .month, value: 1, to: viewingDate) {
            viewingDate = next
            let now = Date()
            updateInfo(now: now, viewingDate: viewingDate)
            markInfoRefreshed(at: now)
        }
    }

    func previousMonth() {
        if let prev = solarCalendar.date(byAdding: .month, value: -1, to: viewingDate) {
            viewingDate = prev
            let now = Date()
            updateInfo(now: now, viewingDate: viewingDate)
            markInfoRefreshed(at: now)
        }
    }

    func goToToday() {
        let now = Date()
        viewingDate = now
        updateInfo(now: now, viewingDate: viewingDate)
        markInfoRefreshed(at: now)
    }

    func snapshot(for date: Date) -> VietnameseLunarSnapshot? {
        lunarService.snapshot(for: date)
    }

    func solarDate(from lunarDate: LunarDate) -> SolarDateComponents? {
        lunarService.solarDate(from: lunarDate)
    }

    var monthWeekdayHeaders: [String] {
        ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]
    }

    private func updateMenuBarTitle(now: Date) {
        guard let snapshot = lunarService.snapshot(for: now) else {
            AppLogger.calendar.warning("Không thể tạo snapshot cho menu bar title tại \(now)")
            return
        }
        let timeComponents = solarCalendar.dateComponents([.hour, .minute, .second], from: now)

        let titleContext = MenuBarTitleContext(
            lunarDay: snapshot.lunar.day,
            lunarMonth: snapshot.lunar.month,
            lunarYear: snapshot.lunar.year,
            isLeapMonth: snapshot.lunar.isLeapMonth,
            canChiYear: snapshot.canChiYear,
            zodiac: snapshot.zodiac,
            solarDay: snapshot.solar.day,
            solarMonth: snapshot.solar.month,
            solarYear: snapshot.solar.year,
            solarWeekdayName: lunarService.weekdayName(from: snapshot.solar.weekday),
            solarWeekdayShortName: lunarService.weekdayShortName(from: snapshot.solar.weekday),
            solarWeekdayNumeric: lunarService.weekdayNumberString(from: snapshot.solar.weekday, style: .oneToSeven),
            solarWeekdayNumericTwoToEight: lunarService.weekdayNumberString(from: snapshot.solar.weekday, style: .twoToEight),
            hour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: timeComponents.second ?? 0
        )

        let preset = settings.menuBarDisplayPreset
        let customTemplate = settings.customMenuBarTemplate

        menuBarTitle = MenuBarTitleFormatter.render(
            preset: preset,
            customTemplate: customTemplate,
            context: titleContext
        )
        menuBarTitleSizingText = MenuBarTitleFormatter.renderForStableTimeWidth(
            preset: preset,
            customTemplate: customTemplate,
            context: titleContext
        )
    }

    private func updateInfo(now: Date, viewingDate: Date) {
        guard
            let snapshot = lunarService.snapshot(for: now),
            let viewingComponents = lunarService.solarComponents(from: viewingDate)
        else {
            AppLogger.calendar.warning("Không thể tạo snapshot hoặc solar components cho info update")
            return
        }

        info = buildInfo(
            now: now,
            snapshot: snapshot,
            viewingSolar: viewingComponents
        )
    }

    private func buildInfo(
        now: Date,
        snapshot: VietnameseLunarSnapshot,
        viewingSolar: SolarDateComponents
    ) -> LunarMenuBarInfo {
        let monthCells = buildMonthCells(year: viewingSolar.year, month: viewingSolar.month, today: snapshot.solar)
        let monthTitle = "Tháng \(viewingSolar.month) năm \(viewingSolar.year)"

        let lunarMonthText = snapshot.lunar.isLeapMonth ? "Tháng \(snapshot.lunar.month) nhuận" : "Tháng \(snapshot.lunar.month)"
        
        let phase = LunarPhase.from(day: snapshot.lunar.day)
        let auspiciousHours = snapshot.hourPeriods.filter(\.isAuspicious)
        let inauspiciousHours = snapshot.hourPeriods.filter { !$0.isAuspicious }
        let nextAuspiciousHourText = formattedNextAuspiciousHour(snapshot.nextAuspiciousHour, now: now)
        let activityInsights = snapshot.dayGuidance.activityInsights.map { insight in
            LunarActivityInsightInfo(
                categoryText: insight.category.rawValue,
                level: mapGuidanceLevel(insight.level),
                reason: insight.reason
            )
        }
        let dayGuidance = LunarDayGuidanceInfo(
            title: snapshot.dayGuidance.title,
            summary: snapshot.dayGuidance.summary,
            score: snapshot.dayGuidance.score,
            ratingText: snapshot.dayGuidance.rating.title,
            recommendedActivities: snapshot.dayGuidance.recommendedActivities,
            avoidActivities: snapshot.dayGuidance.avoidActivities,
            activityInsights: activityInsights
        )
        let dayOfficer = LunarDayOfficerInfo(
            name: snapshot.dayOfficer.name,
            level: mapGuidanceLevel(snapshot.dayOfficer.level),
            summary: snapshot.dayOfficer.summary,
            calculationNote: snapshot.dayOfficer.calculationNote,
            recommendedActivities: snapshot.dayOfficer.recommendedActivities,
            avoidActivities: snapshot.dayOfficer.avoidActivities
        )
        let upcomingHolidays = settings.showHolidaySection ? upcomingHolidays(for: now) : []
        let internationalTimes = settings.showInternationalTimesSection ? buildInternationalTimes(now: now) : []

        return LunarMenuBarInfo(
            weekdayText: lunarService.weekdayName(from: snapshot.solar.weekday),
            solarDateText: snapshot.solar.formattedDate,
            lunarDateText: formattedLunarDate(from: snapshot.lunar),
            lunarDayText: "\(snapshot.lunar.day)",
            lunarMonthYearText: "\(lunarMonthText) năm \(snapshot.canChiYear)",
            leapMonthText: snapshot.lunar.isLeapMonth ? "Tháng nhuận" : nil,
            canChiDayText: snapshot.canChiDay,
            canChiMonthText: snapshot.canChiMonth,
            canChiYearText: snapshot.canChiYear,
            solarTermText: snapshot.solarTerm,
            zodiacText: snapshot.zodiac,
            currentHourCanChiText: snapshot.currentHourCanChi,
            dayElementText: snapshot.dayElement,
            oppositeZodiacText: snapshot.oppositeZodiac,
            tamHopGroupText: snapshot.tamHopGroup,
            nextAuspiciousHourText: nextAuspiciousHourText,
            auspiciousHours: auspiciousHours,
            inauspiciousHours: inauspiciousHours,
            dayGuidance: dayGuidance,
            dayOfficer: dayOfficer,
            weekOfYearText: formattedWeekOfYear(snapshot.solar.weekOfYear),
            dayOfYearText: formattedDayOfYear(snapshot.solar.dayOfYear),
            monthTitleText: monthTitle,
            monthCells: monthCells,
            lunarPhaseIcon: phase.icon,
            lunarPhaseName: phase.name,
            upcomingHolidays: upcomingHolidays,
            internationalTimes: internationalTimes
        )
    }

    private func upcomingHolidays(for now: Date) -> [LunarHoliday] {
        let dayStart = solarCalendar.startOfDay(for: now)
        if let anchor = cachedUpcomingHolidaysAnchor, solarCalendar.isDate(anchor, inSameDayAs: dayStart) {
            return cachedUpcomingHolidays
        }

        let refreshed = calculateUpcomingHolidays(now: dayStart)
        cachedUpcomingHolidays = refreshed
        cachedUpcomingHolidaysAnchor = dayStart
        return refreshed
    }

    private func buildMonthCells(year: Int, month: Int, today: SolarDateComponents) -> [LunarMonthDayCell] {
        let key = YearMonth(year: year, month: month)
        let baseCells: [LunarMonthDayCell]

        if let cachedCells = monthCellsCache[key] {
            // Di chuyển lên đầu danh sách truy cập gần nhất
            if let idx = monthCellsCacheOrder.firstIndex(of: key) {
                monthCellsCacheOrder.remove(at: idx)
            }
            monthCellsCacheOrder.append(key)
            baseCells = cachedCells
        } else {
            let newCells = buildBaseMonthCells(year: year, month: month)
            monthCellsCache[key] = newCells
            monthCellsCacheOrder.append(key)

            // Loại bỏ entry cũ nhất nếu vượt quá giới hạn
            while monthCellsCacheOrder.count > Self.maxCachedMonths {
                let evicted = monthCellsCacheOrder.removeFirst()
                monthCellsCache.removeValue(forKey: evicted)
            }

            baseCells = newCells
        }

        let isViewingCurrentMonth = (year == today.year && month == today.month)

        return baseCells.map { cell in
            guard let solarDay = cell.solarDay else {
                return cell
            }
            return LunarMonthDayCell(
                id: cell.id,
                solarDay: solarDay,
                lunarDay: cell.lunarDay,
                isToday: isViewingCurrentMonth && solarDay == today.day,
                isFirstLunarDay: cell.isFirstLunarDay,
                holiday: cell.holiday
            )
        }
    }

    private func buildBaseMonthCells(year: Int, month: Int) -> [LunarMonthDayCell] {
        guard
            let monthStart = solarCalendar.date(from: DateComponents(year: year, month: month, day: 1)),
            let dayRange = solarCalendar.range(of: .day, in: .month, for: monthStart)
        else {
            return []
        }

        let firstWeekday = solarCalendar.component(.weekday, from: monthStart)
        let leadingEmptyCells = (firstWeekday - solarCalendar.firstWeekday + 7) % 7

        var cells: [LunarMonthDayCell] = []
        var id = 0

        for _ in 0 ..< leadingEmptyCells {
            cells.append(LunarMonthDayCell(id: id, solarDay: nil, lunarDay: nil, isToday: false, isFirstLunarDay: false, holiday: nil))
            id += 1
        }

        for solarDay in dayRange {
            let lunarDate = lunarService.lunarDate(day: solarDay, month: month, year: year)
            let holiday = HolidayProvider.solarHoliday(day: solarDay, month: month) ?? HolidayProvider.lunarHoliday(day: lunarDate.day, month: lunarDate.month)
            
            cells.append(
                LunarMonthDayCell(
                    id: id,
                    solarDay: solarDay,
                    lunarDay: lunarDate.day,
                    isToday: false,
                    isFirstLunarDay: lunarDate.day == 1,
                    holiday: holiday
                )
            )
            id += 1
        }

        while cells.count % 7 != 0 {
            cells.append(LunarMonthDayCell(id: id, solarDay: nil, lunarDay: nil, isToday: false, isFirstLunarDay: false, holiday: nil))
            id += 1
        }

        return cells
    }

    private func calculateUpcomingHolidays(now: Date) -> [LunarHoliday] {
        var holidays: [LunarHoliday] = []
        
        // Check next 30 days
        for i in 0..<31 {
            if let date = solarCalendar.date(byAdding: .day, value: i, to: now),
               let comp = lunarService.solarComponents(from: date),
               let lunar = lunarService.lunarDate(from: date) {
                
                if let solarHoliday = HolidayProvider.solarHoliday(day: comp.day, month: comp.month) {
                    holidays.append(LunarHoliday(name: solarHoliday, dateText: "\(comp.day)/\(comp.month)", isLunar: false, daysUntil: i))
                } else if let lunarHoliday = HolidayProvider.lunarHoliday(day: lunar.day, month: lunar.month) {
                    holidays.append(LunarHoliday(name: lunarHoliday, dateText: "\(lunar.day)/\(lunar.month) ÂL", isLunar: true, daysUntil: i))
                }
            }
        }
        
        return holidays.sorted { $0.daysUntil < $1.daysUntil }
    }

    private func buildInternationalTimes(now: Date) -> [InternationalTimeInfo] {
        let localCalendar = Calendar.autoupdatingCurrent
        let localDayOrdinal = localCalendar.ordinality(of: .day, in: .era, for: now)

        return settings.selectedInternationalTimeZones.compactMap { preset -> InternationalTimeInfo? in
            guard let timeZone = TimeZone(identifier: preset.id) else {
                return nil
            }

            let targetCalendar = Self.internationalCalendar(for: timeZone)
            let dayOffset = relativeDayOffset(
                at: now,
                localDayOrdinal: localDayOrdinal,
                targetCalendar: targetCalendar
            )

            let timeText = formattedClockTime(now, timeZone: timeZone)
            let weekdayText = formattedClockWeekday(now, timeZone: timeZone)

            return InternationalTimeInfo(
                id: preset.id,
                city: preset.city,
                timeText: timeText,
                weekdayText: weekdayText,
                utcOffsetText: formattedUTCOffset(for: timeZone, at: now),
                relativeDayText: relativeDayText(for: dayOffset)
            )
        }
    }

    private func formattedUTCOffset(for timeZone: TimeZone, at date: Date) -> String {
        let offsetMinutes = timeZone.secondsFromGMT(for: date) / 60
        let sign = offsetMinutes >= 0 ? "+" : "-"
        let absoluteMinutes = abs(offsetMinutes)
        let hours = absoluteMinutes / 60
        let minutes = absoluteMinutes % 60

        if minutes == 0 {
            return String(format: "UTC%@%02d", sign, hours)
        }

        return String(format: "UTC%@%02d:%02d", sign, hours, minutes)
    }

    private func relativeDayOffset(at date: Date, localDayOrdinal: Int?, targetCalendar: Calendar) -> Int {
        guard
            let localDay = localDayOrdinal,
            let targetDay = targetCalendar.ordinality(of: .day, in: .era, for: date)
        else {
            return 0
        }

        return targetDay - localDay
    }

    private func formattedClockTime(_ date: Date, timeZone: TimeZone) -> String {
        Self.internationalClockTimeFormatter(for: timeZone).string(from: date)
    }

    private func formattedClockWeekday(_ date: Date, timeZone: TimeZone) -> String {
        let weekday = Self.internationalClockWeekdayFormatter(for: timeZone).string(from: date)
        return weekday.capitalized(with: Self.internationalClockLocale)
    }

    private static func internationalClockTimeFormatter(for timeZone: TimeZone) -> DateFormatter {
        if let formatter = internationalClockTimeFormatterByTimeZoneID[timeZone.identifier] {
            return formatter
        }

        let formatter = DateFormatter()
        formatter.locale = internationalClockLocale
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        internationalClockTimeFormatterByTimeZoneID[timeZone.identifier] = formatter
        return formatter
    }

    private static func internationalClockWeekdayFormatter(for timeZone: TimeZone) -> DateFormatter {
        if let formatter = internationalClockWeekdayFormatterByTimeZoneID[timeZone.identifier] {
            return formatter
        }

        let formatter = DateFormatter()
        formatter.locale = internationalClockLocale
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEE"
        internationalClockWeekdayFormatterByTimeZoneID[timeZone.identifier] = formatter
        return formatter
    }

    private static func internationalCalendar(for timeZone: TimeZone) -> Calendar {
        if let cachedCalendar = internationalCalendarByTimeZoneID[timeZone.identifier] {
            return cachedCalendar
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        internationalCalendarByTimeZoneID[timeZone.identifier] = calendar
        return calendar
    }

    private func relativeDayText(for dayOffset: Int) -> String {
        switch dayOffset {
        case 0:
            return "Hôm nay"
        case 1:
            return "Ngày mai"
        case -1:
            return "Hôm qua"
        case let value where value > 1:
            return "+\(value) ngày"
        default:
            return "\(dayOffset) ngày"
        }
    }

    private func formattedLunarDate(from lunarDate: LunarDate) -> String {
        var text = String(format: "%02d/%02d", lunarDate.day, lunarDate.month)
        if lunarDate.isLeapMonth {
            text += " (nhuận)"
        }
        return text
    }

    private func formattedNextAuspiciousHour(_ window: VietnameseAuspiciousHourWindow?, now: Date) -> String {
        guard let window else {
            return "Không có dữ liệu"
        }

        let isActiveNow = window.startDate <= now && now < window.endDate

        let dayLabel: String
        if isActiveNow {
            dayLabel = "Hiện tại"
        } else if solarCalendar.isDate(window.startDate, inSameDayAs: now) {
            dayLabel = "Hôm nay"
        } else if
            let tomorrow = solarCalendar.date(byAdding: .day, value: 1, to: now),
            solarCalendar.isDate(window.startDate, inSameDayAs: tomorrow)
        {
            dayLabel = "Ngày mai"
        } else {
            dayLabel = window.startDate.formatted(.dateTime.day().month().locale(Locale(identifier: "vi_VN")))
        }

        let progressText: String
        if isActiveNow {
            progressText = "đang diễn ra"
        } else {
            let timeUntilStart = max(Int(window.startDate.timeIntervalSince(now)), 0)
            let hours = timeUntilStart / 3600
            let minutes = (timeUntilStart % 3600) / 60

            if hours > 0 {
                progressText = minutes > 0 ? "còn \(hours)h \(minutes)p" : "còn \(hours)h"
            } else {
                progressText = "còn \(max(minutes, 1)) phút"
            }
        }

        return "\(window.period.canChi) \(window.period.timeRange) • \(dayLabel) • \(progressText)"
    }

    private func mapGuidanceLevel(_ level: VietnameseGuidanceLevel) -> LunarGuidanceLevelInfo {
        switch level {
        case .favorable:
            return .favorable
        case .neutral:
            return .neutral
        case .caution:
            return .caution
        }
    }

    private func shouldRefreshInfo(at now: Date) -> Bool {
        minuteBucket(for: now) != lastInfoRefreshMinuteBucket
    }

    private func markInfoRefreshed(at date: Date) {
        lastInfoRefreshMinuteBucket = minuteBucket(for: date)
    }

    private func minuteBucket(for date: Date) -> Int {
        Int(date.timeIntervalSince1970 / 60)
    }

    private func scheduleRefresh(from now: Date) {
        refreshTask?.cancel()

        let titleGranularity = MenuBarTitleFormatter.refreshGranularity(
            preset: settings.menuBarDisplayPreset,
            customTemplate: settings.customMenuBarTemplate
        )
        let needsWorldClockMinuteRefresh = settings.showInternationalTimesSection
        let granularity: MenuBarTitleFormatter.RefreshGranularity
        if needsWorldClockMinuteRefresh, titleGranularity == .daily {
            granularity = .everyMinute
        } else {
            granularity = titleGranularity
        }

        let delay: TimeInterval
        switch granularity {
        case .everySecond:
            let nextSecond = nextSecondStart(from: now)
            delay = max(nextSecond.timeIntervalSince(now) + 0.05, 0.05)
        case .everyMinute:
            let nextMinute = nextMinuteStart(from: now)
            delay = max(nextMinute.timeIntervalSince(now) + 0.1, 0.1)
        case .daily:
            // Refresh mỗi 5 phút cho chế độ không hiển thị giờ
            delay = 300
        }

        refreshTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard let self, !Task.isCancelled else {
                return
            }
            self.refresh()
        }
    }

    private func startObservingSystemChanges() {
        let defaultCenter = NotificationCenter.default
        let systemNames: [Notification.Name] = [
            .NSSystemClockDidChange,
            .NSSystemTimeZoneDidChange,
            .NSCalendarDayChanged,
        ]

        systemNotificationObservers = systemNames.map { name in
            defaultCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.invalidateCaches()
                    self?.refresh(forceInfo: true)
                }
            }
        }

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        let wakeObserver = workspaceCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.invalidateCaches()
                self?.refresh(forceInfo: true)
            }
        }
        workspaceNotificationObservers = [wakeObserver]
    }

    private func startObservingSettings() {
        settings.objectWillChange
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }

                let currentSettings = RefreshSettings(settings: self.settings)
                guard currentSettings != self.lastObservedRefreshSettings else {
                    return
                }
                self.lastObservedRefreshSettings = currentSettings

                Task { @MainActor [weak self] in
                    self?.refresh(forceInfo: true)
                }
            }
            .store(in: &settingsCancellables)
    }

    private func nextSecondStart(from now: Date) -> Date {
        guard let secondStart = solarCalendar.dateInterval(of: .second, for: now)?.start else {
            return now.addingTimeInterval(1)
        }

        return solarCalendar.date(byAdding: .second, value: 1, to: secondStart) ?? now.addingTimeInterval(1)
    }

    private func nextMinuteStart(from now: Date) -> Date {
        guard let minuteStart = solarCalendar.dateInterval(of: .minute, for: now)?.start else {
            return now.addingTimeInterval(60)
        }

        return solarCalendar.date(byAdding: .minute, value: 1, to: minuteStart) ?? now.addingTimeInterval(60)
    }

    private func formattedWeekOfYear(_ week: Int?) -> String {
        guard let week else {
            return "--"
        }
        return "Tuần \(week)"
    }

    private func formattedDayOfYear(_ day: Int?) -> String {
        guard let day else {
            return "--"
        }
        return "Ngày thứ \(day)"
    }

}
