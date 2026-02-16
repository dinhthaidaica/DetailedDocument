//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import AppKit
import Combine
import Foundation

@MainActor
final class LunarMenuBarViewModel: ObservableObject {
    @Published private(set) var menuBarTitle = "--/-- ÂL"
    @Published private(set) var info = LunarMenuBarInfo.placeholder
    @Published private(set) var viewingDate: Date
    
    // Xuất bản settings để View có thể quan sát
    @Published var settings: AppSettings

    private struct YearMonth: Hashable {
        let year: Int
        let month: Int
    }

    private static let defaultVietnamTimeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? TimeZone(secondsFromGMT: 7 * 3600) ?? .current

    private let solarCalendar: Calendar
    private let lunarConverter: any LunarDateConverting
    private let vietnamTimeZone: TimeZone
    private var refreshTask: Task<Void, Never>?
    private var systemNotificationObservers: [NSObjectProtocol] = []
    private var workspaceNotificationObservers: [NSObjectProtocol] = []
    private var settingsCancellables = Set<AnyCancellable>()
    private var monthCellsCache: [YearMonth: [LunarMonthDayCell]] = [:]
    private var cachedUpcomingHolidays: [LunarHoliday] = []
    private var cachedUpcomingHolidaysAnchor: Date?

    init(
        solarCalendar: Calendar = Calendar(identifier: .gregorian),
        lunarConverter: (any LunarDateConverting)? = nil,
        settings: AppSettings? = nil
    ) {
        let vietnamTimeZone = Self.defaultVietnamTimeZone
        var calendar = solarCalendar
        calendar.timeZone = vietnamTimeZone
        calendar.locale = Locale(identifier: "vi_VN")
        calendar.firstWeekday = 2

        self.vietnamTimeZone = vietnamTimeZone
        self.solarCalendar = calendar
        self.lunarConverter = lunarConverter ?? VietnameseLunarCalendarConverter(timeZone: 7.0)
        
        let targetSettings = settings ?? AppSettings.shared
        self.settings = targetSettings
        self.viewingDate = Date()

        startObservingSettings()
        startObservingSystemChanges()
        refresh()
    }

    func refresh() {
        let now = Date()
        updateMenuBarTitle(now: now)
        updateInfo(now: now, viewingDate: viewingDate)
        scheduleRefresh(from: now)
    }

    func nextMonth() {
        if let next = solarCalendar.date(byAdding: .month, value: 1, to: viewingDate) {
            viewingDate = next
            updateInfo(now: Date(), viewingDate: viewingDate)
        }
    }

    func previousMonth() {
        if let prev = solarCalendar.date(byAdding: .month, value: -1, to: viewingDate) {
            viewingDate = prev
            updateInfo(now: Date(), viewingDate: viewingDate)
        }
    }

    func goToToday() {
        viewingDate = Date()
        updateInfo(now: viewingDate, viewingDate: viewingDate)
    }

    private func updateMenuBarTitle(now: Date) {
        guard let components = solarDayComponents(from: now) else { return }
        let lunarDate = lunarConverter.solarToLunar(day: components.day, month: components.month, year: components.year)
        let canChiYear = VietnameseCalendarMetadata.canChiYear(lunarYear: lunarDate.year)
        let zodiac = VietnameseCalendarMetadata.zodiac(lunarYear: lunarDate.year)

        let titleContext = MenuBarTitleContext(
            lunarDay: lunarDate.day,
            lunarMonth: lunarDate.month,
            lunarYear: lunarDate.year,
            isLeapMonth: lunarDate.isLeapMonth,
            canChiYear: canChiYear,
            zodiac: zodiac,
            solarDay: components.day,
            solarMonth: components.month,
            solarYear: components.year
        )

        menuBarTitle = MenuBarTitleFormatter.render(
            preset: settings.menuBarDisplayPreset,
            customTemplate: settings.customMenuBarTemplate,
            context: titleContext
        )
    }

    private func updateInfo(now: Date, viewingDate: Date) {
        guard let nowComponents = solarDayComponents(from: now),
              let viewingComponents = solarDayComponents(from: viewingDate) else { return }

        let lunarDate = lunarConverter.solarToLunar(
            day: nowComponents.day,
            month: nowComponents.month,
            year: nowComponents.year
        )

        let canChiYear = VietnameseCalendarMetadata.canChiYear(lunarYear: lunarDate.year)
        let zodiac = VietnameseCalendarMetadata.zodiac(lunarYear: lunarDate.year)

        info = buildInfo(
            now: now,
            viewingDate: viewingDate,
            solar: nowComponents,
            viewingSolar: viewingComponents,
            lunar: lunarDate,
            canChiYear: canChiYear,
            zodiac: zodiac
        )
    }

    private func buildInfo(
        now: Date,
        viewingDate: Date,
        solar: (day: Int, month: Int, year: Int, weekday: Int?, weekOfYear: Int?, dayOfYear: Int?),
        viewingSolar: (day: Int, month: Int, year: Int, weekday: Int?, weekOfYear: Int?, dayOfYear: Int?),
        lunar: LunarDate,
        canChiYear: String,
        zodiac: String
    ) -> LunarMenuBarInfo {
        let canChiDay = VietnameseCalendarMetadata.canChiDay(day: solar.day, month: solar.month, year: solar.year)
        let canChiMonth = VietnameseCalendarMetadata.canChiMonth(lunarMonth: lunar.month, lunarYear: lunar.year)
        let currentHourCanChi = VietnameseCalendarMetadata.canChiHour(
            date: now,
            day: solar.day,
            month: solar.month,
            year: solar.year,
            calendar: solarCalendar
        )

        let monthCells = buildMonthCells(year: viewingSolar.year, month: viewingSolar.month, today: solar)
        let monthTitle = "Tháng \(viewingSolar.month) năm \(viewingSolar.year)"

        let lunarMonthText = lunar.isLeapMonth ? "Tháng \(lunar.month) nhuận" : "Tháng \(lunar.month)"
        
        let phase = lunarPhase(lunarDay: lunar.day)

        return LunarMenuBarInfo(
            weekdayText: Self.weekdayName(from: solar.weekday),
            solarDateText: String(format: "%02d/%02d/%04d", solar.day, solar.month, solar.year),
            lunarDateText: formattedLunarDate(from: lunar),
            lunarDayText: "\(lunar.day)",
            lunarMonthYearText: "\(lunarMonthText) năm \(canChiYear)",
            leapMonthText: lunar.isLeapMonth ? "Tháng nhuận" : nil,
            canChiDayText: canChiDay,
            canChiMonthText: canChiMonth,
            canChiYearText: canChiYear,
            solarTermText: VietnameseCalendarMetadata.solarTerm(date: now, timeZone: vietnamTimeZone),
            zodiacText: zodiac,
            currentHourCanChiText: currentHourCanChi,
            weekOfYearText: formattedWeekOfYear(solar.weekOfYear),
            dayOfYearText: formattedDayOfYear(solar.dayOfYear),
            monthTitleText: monthTitle,
            monthCells: monthCells,
            lunarPhaseIcon: phase.icon,
            lunarPhaseName: phase.name,
            upcomingHolidays: upcomingHolidays(for: now)
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

    private func buildMonthCells(year: Int, month: Int, today: (day: Int, month: Int, year: Int, weekday: Int?, weekOfYear: Int?, dayOfYear: Int?)) -> [LunarMonthDayCell] {
        let key = YearMonth(year: year, month: month)
        let baseCells: [LunarMonthDayCell]

        if let cachedCells = monthCellsCache[key] {
            baseCells = cachedCells
        } else {
            let newCells = buildBaseMonthCells(year: year, month: month)
            monthCellsCache[key] = newCells
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
            let lunarDate = lunarConverter.solarToLunar(day: solarDay, month: month, year: year)
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

    private func lunarPhase(lunarDay: Int) -> (icon: String, name: String) {
        switch lunarDay {
        case 1: return ("moonphase.new.moon", "Trăng mới")
        case 2...7: return ("moonphase.waxing.crescent", "Trăng lưỡi liềm")
        case 8: return ("moonphase.first.quarter", "Trăng bán nguyệt đầu tháng")
        case 9...14: return ("moonphase.waxing.gibbous", "Trăng khuyết đầu tháng")
        case 15: return ("moonphase.full.moon", "Trăng tròn")
        case 16...22: return ("moonphase.waning.gibbous", "Trăng khuyết cuối tháng")
        case 23: return ("moonphase.last.quarter", "Trăng bán nguyệt cuối tháng")
        case 24...29: return ("moonphase.waning.crescent", "Trăng lưỡi liềm cuối tháng")
        case 30: return ("moonphase.new.moon", "Trăng mới")
        default: return ("moon.fill", "--")
        }
    }

    private func calculateUpcomingHolidays(now: Date) -> [LunarHoliday] {
        var holidays: [LunarHoliday] = []
        
        // Check next 30 days
        for i in 0..<31 {
            if let date = solarCalendar.date(byAdding: .day, value: i, to: now),
               let comp = solarDayComponents(from: date) {
                
                let lunar = lunarConverter.solarToLunar(day: comp.day, month: comp.month, year: comp.year)
                
                if let solarHoliday = HolidayProvider.solarHoliday(day: comp.day, month: comp.month) {
                    holidays.append(LunarHoliday(name: solarHoliday, dateText: "\(comp.day)/\(comp.month)", isLunar: false, daysUntil: i))
                } else if let lunarHoliday = HolidayProvider.lunarHoliday(day: lunar.day, month: lunar.month) {
                    holidays.append(LunarHoliday(name: lunarHoliday, dateText: "\(lunar.day)/\(lunar.month) ÂL", isLunar: true, daysUntil: i))
                }
            }
        }
        
        return holidays.sorted { $0.daysUntil < $1.daysUntil }
    }

    private func formattedLunarDate(from lunarDate: LunarDate) -> String {
        var text = String(format: "%02d/%02d", lunarDate.day, lunarDate.month)
        if lunarDate.isLeapMonth {
            text += " (nhuận)"
        }
        return text
    }

    private func scheduleRefresh(from now: Date) {
        refreshTask?.cancel()

        let nextRefreshDate = nextSecondStart(from: now)
        let delay = max(nextRefreshDate.timeIntervalSince(now) + 0.05, 0.05)

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
                    self?.refresh()
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
                self?.refresh()
            }
        }
        workspaceNotificationObservers = [wakeObserver]
    }

    private func startObservingSettings() {
        // Quan sát thay đổi từ settings object trực tiếp
        settings.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    // Kích hoạt refresh khi bất kỳ setting nào thay đổi
                    self?.refresh()
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

    private func solarDayComponents(from date: Date) -> (day: Int, month: Int, year: Int, weekday: Int?, weekOfYear: Int?, dayOfYear: Int?)? {
        let components = solarCalendar.dateComponents([.day, .month, .year, .weekday, .weekOfYear, .dayOfYear], from: date)
        guard
            let day = components.day,
            let month = components.month,
            let year = components.year
        else {
            return nil
        }
        return (day, month, year, components.weekday, components.weekOfYear, components.dayOfYear)
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

    private static func weekdayName(from weekday: Int?) -> String {
        let names = ["Chủ nhật", "Thứ hai", "Thứ ba", "Thứ tư", "Thứ năm", "Thứ sáu", "Thứ bảy"]
        guard let weekday else {
            return "Hôm nay"
        }
        let normalized = min(max(weekday, 1), 7)
        return names[normalized - 1]
    }
}
