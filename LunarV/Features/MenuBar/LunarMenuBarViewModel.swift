import AppKit
import Combine
import Foundation

@MainActor
final class LunarMenuBarViewModel: ObservableObject {
    @Published private(set) var menuBarTitle = "--/-- ÂL"
    @Published private(set) var info = LunarMenuBarInfo.placeholder

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
    private var monthCellsCache: [YearMonth: [LunarMonthDayCell]] = [:]

    init(
        solarCalendar: Calendar = Calendar(identifier: .gregorian),
        lunarConverter: (any LunarDateConverting)? = nil
    ) {
        let vietnamTimeZone = Self.defaultVietnamTimeZone
        var calendar = solarCalendar
        calendar.timeZone = vietnamTimeZone
        calendar.locale = Locale(identifier: "vi_VN")
        calendar.firstWeekday = 2

        self.vietnamTimeZone = vietnamTimeZone
        self.solarCalendar = calendar
        self.lunarConverter = lunarConverter ?? VietnameseLunarCalendarConverter(timeZone: 7.0)

        startObservingSystemChanges()
        refresh()
    }

    deinit {
        refreshTask?.cancel()

        let defaultCenter = NotificationCenter.default
        for observer in systemNotificationObservers {
            defaultCenter.removeObserver(observer)
        }

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        for observer in workspaceNotificationObservers {
            workspaceCenter.removeObserver(observer)
        }
    }

    func refresh() {
        let now = Date()
        guard let components = solarDayComponents(from: now) else {
            return
        }

        let lunarDate = lunarConverter.solarToLunar(
            day: components.day,
            month: components.month,
            year: components.year
        )

        menuBarTitle = String(format: "%02d/%02d ÂL", lunarDate.day, lunarDate.month)
        info = buildInfo(now: now, solar: components, lunar: lunarDate)

        scheduleRefresh(from: now)
    }

    private func buildInfo(
        now: Date,
        solar: (day: Int, month: Int, year: Int, weekday: Int?, weekOfYear: Int?, dayOfYear: Int?),
        lunar: LunarDate
    ) -> LunarMenuBarInfo {
        let canChiDay = VietnameseCalendarMetadata.canChiDay(day: solar.day, month: solar.month, year: solar.year)
        let canChiMonth = VietnameseCalendarMetadata.canChiMonth(lunarMonth: lunar.month, lunarYear: lunar.year)
        let canChiYear = VietnameseCalendarMetadata.canChiYear(lunarYear: lunar.year)
        let currentHourCanChi = VietnameseCalendarMetadata.canChiHour(
            date: now,
            day: solar.day,
            month: solar.month,
            year: solar.year,
            calendar: solarCalendar
        )

        let monthCells = buildMonthCells(year: solar.year, month: solar.month, today: solar.day)
        let monthTitle = "Tháng \(solar.month) năm \(solar.year)"

        let lunarMonthText = lunar.isLeapMonth ? "Tháng \(lunar.month) nhuận" : "Tháng \(lunar.month)"

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
            zodiacText: VietnameseCalendarMetadata.zodiac(lunarYear: lunar.year),
            currentHourCanChiText: currentHourCanChi,
            weekOfYearText: formattedWeekOfYear(solar.weekOfYear),
            dayOfYearText: formattedDayOfYear(solar.dayOfYear),
            monthTitleText: monthTitle,
            monthCells: monthCells
        )
    }

    private func buildMonthCells(year: Int, month: Int, today: Int) -> [LunarMonthDayCell] {
        let key = YearMonth(year: year, month: month)
        let baseCells: [LunarMonthDayCell]

        if let cachedCells = monthCellsCache[key] {
            baseCells = cachedCells
        } else {
            let newCells = buildBaseMonthCells(year: year, month: month)
            monthCellsCache[key] = newCells
            baseCells = newCells
        }

        return baseCells.map { cell in
            guard let solarDay = cell.solarDay else {
                return cell
            }
            return LunarMonthDayCell(
                id: cell.id,
                solarDay: solarDay,
                lunarDay: cell.lunarDay,
                isToday: solarDay == today,
                isFirstLunarDay: cell.isFirstLunarDay
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
            cells.append(LunarMonthDayCell(id: id, solarDay: nil, lunarDay: nil, isToday: false, isFirstLunarDay: false))
            id += 1
        }

        for solarDay in dayRange {
            let lunarDate = lunarConverter.solarToLunar(day: solarDay, month: month, year: year)
            cells.append(
                LunarMonthDayCell(
                    id: id,
                    solarDay: solarDay,
                    lunarDay: lunarDate.day,
                    isToday: false,
                    isFirstLunarDay: lunarDate.day == 1
                )
            )
            id += 1
        }

        while cells.count % 7 != 0 {
            cells.append(LunarMonthDayCell(id: id, solarDay: nil, lunarDay: nil, isToday: false, isFirstLunarDay: false))
            id += 1
        }

        return cells
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

        let nextMinute = nextMinuteStart(from: now)
        let nextMidnight = nextDayStart(from: now)
        let nextCanChiHour = nextCanChiHourBoundary(from: now)
        let nextRefreshDate = min(nextMinute, min(nextMidnight, nextCanChiHour))
        let delay = max(nextRefreshDate.timeIntervalSince(now) + 0.2, 0.2)

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

    private func nextMinuteStart(from now: Date) -> Date {
        guard let minuteStart = solarCalendar.dateInterval(of: .minute, for: now)?.start else {
            return now.addingTimeInterval(60)
        }

        return solarCalendar.date(byAdding: .minute, value: 1, to: minuteStart) ?? now.addingTimeInterval(60)
    }

    private func nextDayStart(from now: Date) -> Date {
        let startOfToday = solarCalendar.startOfDay(for: now)
        return solarCalendar.date(byAdding: .day, value: 1, to: startOfToday) ?? now.addingTimeInterval(86_400)
    }

    private func nextCanChiHourBoundary(from now: Date) -> Date {
        guard let hourStart = solarCalendar.dateInterval(of: .hour, for: now)?.start else {
            return now.addingTimeInterval(7_200)
        }

        let hour = solarCalendar.component(.hour, from: now)
        let hourOffset = hour.isMultiple(of: 2) ? 1 : 2
        return solarCalendar.date(byAdding: .hour, value: hourOffset, to: hourStart) ?? now.addingTimeInterval(7_200)
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
