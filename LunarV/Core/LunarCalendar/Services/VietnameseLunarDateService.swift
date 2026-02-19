//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.lunarv", category: "calendar")

enum WeekdayDisplayStyle: String, CaseIterable, Identifiable {
    case full
    case short
    case numeric

    var id: String { rawValue }

    var title: String {
        switch self {
        case .full:
            return "Đầy đủ"
        case .short:
            return "Viết tắt"
        case .numeric:
            return "Số 1-7"
        }
    }

    var subtitle: String {
        switch self {
        case .full:
            return "Hiển thị dạng Thứ Hai, Thứ Ba..."
        case .short:
            return "Hiển thị dạng T2, T3... như hiện nay"
        case .numeric:
            return "Hiển thị theo số đếm 1-7 (Thứ Hai = 1)"
        }
    }

    func weekdayName(from weekday: Int?) -> String {
        guard let weekday, (1 ... 7).contains(weekday) else {
            return fallbackWeekdayName
        }

        switch self {
        case .full:
            return VietnameseLunarDateService.weekdayNames[weekday - 1]
        case .short:
            return VietnameseLunarDateService.weekdayShortNames[weekday - 1]
        case .numeric:
            return "\(isoWeekdayNumber(from: weekday))"
        }
    }

    func weekdayShortName(from weekday: Int?) -> String {
        guard let weekday, (1 ... 7).contains(weekday) else {
            return fallbackWeekdayShortName
        }

        switch self {
        case .full:
            return VietnameseLunarDateService.weekdayShortNames[weekday - 1]
        case .short:
            return VietnameseLunarDateService.weekdayShortNames[weekday - 1]
        case .numeric:
            return "\(isoWeekdayNumber(from: weekday))"
        }
    }

    var monthHeaderSymbols: [String] {
        switch self {
        case .full, .short:
            return [2, 3, 4, 5, 6, 7, 1].map { VietnameseLunarDateService.weekdayShortNames[$0 - 1] }
        case .numeric:
            return (1 ... 7).map(String.init)
        }
    }

    private var fallbackWeekdayName: String {
        switch self {
        case .full:
            return VietnameseLunarDateService.weekdayNames[0]
        case .short:
            return VietnameseLunarDateService.weekdayShortNames[0]
        case .numeric:
            return "7"
        }
    }

    private var fallbackWeekdayShortName: String {
        switch self {
        case .full, .short:
            return VietnameseLunarDateService.weekdayShortNames[0]
        case .numeric:
            return "7"
        }
    }

    private func isoWeekdayNumber(from weekday: Int) -> Int {
        weekday == 1 ? 7 : weekday - 1
    }
}

enum WeekdayNumericStyle: String, CaseIterable, Identifiable {
    case oneToSeven
    case twoToEight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneToSeven:
            return "Chuẩn 1-7"
        case .twoToEight:
            return "Mở rộng 2-8"
        }
    }

    var subtitle: String {
        switch self {
        case .oneToSeven:
            return "T2 = 1, ... CN = 7"
        case .twoToEight:
            return "T2 = 2, ... CN = 8"
        }
    }

    func value(from weekday: Int?) -> String {
        guard let weekday, (1 ... 7).contains(weekday) else {
            return fallbackValue
        }
        let isoWeekday = weekday == 1 ? 7 : weekday - 1
        let displayValue = self == .twoToEight ? isoWeekday + 1 : isoWeekday
        return "\(displayValue)"
    }

    private var fallbackValue: String {
        self == .twoToEight ? "8" : "7"
    }
}

struct VietnameseLunarDateService {
    static let defaultTimeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        ?? TimeZone(secondsFromGMT: 7 * 3600)
        ?? .current
    static let defaultSolarTimeZone = TimeZone.autoupdatingCurrent
    static let weekdayNames = ["Chủ Nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy"]
    static let weekdayShortNames = ["CN", "T2", "T3", "T4", "T5", "T6", "T7"]

    let timeZone: TimeZone
    let solarTimeZone: TimeZone
    let calendar: Calendar
    private let vietnamCalendar: Calendar
    private let lunarConverter: any LunarDateConverting

    init(
        timeZone: TimeZone = VietnameseLunarDateService.defaultTimeZone,
        solarTimeZone: TimeZone = VietnameseLunarDateService.defaultSolarTimeZone,
        calendar: Calendar = Calendar(identifier: .gregorian),
        lunarConverter: (any LunarDateConverting)? = nil
    ) {
        var configuredSolarCalendar = calendar
        configuredSolarCalendar.timeZone = solarTimeZone
        configuredSolarCalendar.locale = Locale(identifier: "vi_VN")
        configuredSolarCalendar.firstWeekday = 2

        var configuredVietnamCalendar = calendar
        configuredVietnamCalendar.timeZone = timeZone
        configuredVietnamCalendar.locale = Locale(identifier: "vi_VN")
        configuredVietnamCalendar.firstWeekday = 2

        self.timeZone = timeZone
        self.solarTimeZone = solarTimeZone
        self.calendar = configuredSolarCalendar
        self.vietnamCalendar = configuredVietnamCalendar
        self.lunarConverter = lunarConverter ?? VietnameseLunarCalendarConverter(timeZone: 7.0)
    }

    func solarComponents(from date: Date) -> SolarDateComponents? {
        solarComponents(from: date, using: calendar)
    }

    private func vietnamSolarComponents(from date: Date) -> SolarDateComponents? {
        solarComponents(from: date, using: vietnamCalendar)
    }

    private func solarComponents(from date: Date, using calendar: Calendar) -> SolarDateComponents? {
        let components = calendar.dateComponents([.day, .month, .year, .weekday, .weekOfYear, .dayOfYear], from: date)
        guard
            let day = components.day,
            let month = components.month,
            let year = components.year
        else {
            return nil
        }

        return SolarDateComponents(
            day: day,
            month: month,
            year: year,
            weekday: components.weekday,
            weekOfYear: components.weekOfYear,
            dayOfYear: components.dayOfYear
        )
    }

    func lunarDate(day: Int, month: Int, year: Int) -> LunarDate {
        lunarConverter.solarToLunar(day: day, month: month, year: year)
    }

    func lunarDate(from date: Date) -> LunarDate? {
        guard let solar = vietnamSolarComponents(from: date) else {
            return nil
        }
        return lunarDate(day: solar.day, month: solar.month, year: solar.year)
    }

    func solarDate(from targetLunarDate: LunarDate) -> SolarDateComponents? {
        // Ước lượng ngày dương gần đúng từ ngày âm, sau đó tìm trong cửa sổ hẹp ±35 ngày
        // thay vì brute-force qua toàn bộ 3 năm (~1,080 ngày)
        let estimatedMonth = targetLunarDate.month
        let estimatedYear = targetLunarDate.year
        let estimatedDay = min(targetLunarDate.day, 28)

        guard let centerDate = vietnamCalendar.date(from: DateComponents(
            year: estimatedYear,
            month: estimatedMonth,
            day: estimatedDay
        )) else {
            logger.error("Không thể tạo center date cho lunar→solar: \(targetLunarDate.day)/\(targetLunarDate.month)/\(targetLunarDate.year)")
            return nil
        }

        // Tìm trong cửa sổ ±35 ngày (~70 ngày thay vì ~1,080)
        for offset in -35...35 {
            guard
                let candidateDate = vietnamCalendar.date(byAdding: .day, value: offset, to: centerDate),
                let solar = solarComponents(from: candidateDate, using: vietnamCalendar)
            else {
                continue
            }

            let candidateLunar = lunarDate(day: solar.day, month: solar.month, year: solar.year)
            if candidateLunar == targetLunarDate {
                return solar
            }
        }

        return nil
    }

    func nextAuspiciousHour(from date: Date, lookAheadDays: Int = 2) -> VietnameseAuspiciousHourWindow? {
        let boundedLookAheadDays = max(lookAheadDays, 0)
        let dayStart = vietnamCalendar.startOfDay(for: date)

        for dayOffset in 0 ... boundedLookAheadDays {
            guard
                let targetDay = vietnamCalendar.date(byAdding: .day, value: dayOffset, to: dayStart),
                let solar = vietnamSolarComponents(from: targetDay)
            else {
                continue
            }

            let periods = VietnameseCalendarMetadata.hourPeriods(day: solar.day, month: solar.month, year: solar.year)
            for period in periods where period.isAuspicious {
                guard
                    let interval = hourInterval(for: period.branchIndex, on: targetDay),
                    interval.end > date
                else {
                    continue
                }

                return VietnameseAuspiciousHourWindow(
                    period: period,
                    startDate: interval.start,
                    endDate: interval.end
                )
            }
        }

        return nil
    }

    func snapshot(for date: Date) -> VietnameseLunarSnapshot? {
        guard
            let solar = solarComponents(from: date),
            let vietnamSolar = vietnamSolarComponents(from: date)
        else {
            return nil
        }

        let lunar = lunarDate(day: vietnamSolar.day, month: vietnamSolar.month, year: vietnamSolar.year)
        let canChiDay = VietnameseCalendarMetadata.canChiDay(day: vietnamSolar.day, month: vietnamSolar.month, year: vietnamSolar.year)
        let canChiMonth = VietnameseCalendarMetadata.canChiMonth(lunarMonth: lunar.month, lunarYear: lunar.year)
        let canChiYear = VietnameseCalendarMetadata.canChiYear(lunarYear: lunar.year)
        let zodiac = VietnameseCalendarMetadata.zodiac(lunarYear: lunar.year)
        let solarTerm = VietnameseCalendarMetadata.solarTerm(date: date, timeZone: timeZone)
        let currentHourCanChi = VietnameseCalendarMetadata.canChiHour(
            date: date,
            day: vietnamSolar.day,
            month: vietnamSolar.month,
            year: vietnamSolar.year,
            calendar: vietnamCalendar
        )
        let dayElement = VietnameseCalendarMetadata.dayElement(day: vietnamSolar.day, month: vietnamSolar.month, year: vietnamSolar.year)
        let oppositeZodiac = VietnameseCalendarMetadata.oppositeZodiac(day: vietnamSolar.day, month: vietnamSolar.month, year: vietnamSolar.year)
        let tamHopGroup = VietnameseCalendarMetadata.tamHopGroup(day: vietnamSolar.day, month: vietnamSolar.month, year: vietnamSolar.year)
        let hourPeriods = VietnameseCalendarMetadata.hourPeriods(day: vietnamSolar.day, month: vietnamSolar.month, year: vietnamSolar.year)
        let dayGuidance = VietnameseDayGuidanceProvider.guidance(dayElement: dayElement, solarTerm: solarTerm)
        let dayOfficer = VietnameseDayOfficerProvider.officer(
            lunarMonth: lunar.month,
            solarDay: vietnamSolar.day,
            solarMonth: vietnamSolar.month,
            solarYear: vietnamSolar.year
        )
        let nextAuspiciousHour = nextAuspiciousHour(from: date)

        return VietnameseLunarSnapshot(
            solar: solar,
            lunar: lunar,
            canChiDay: canChiDay,
            canChiMonth: canChiMonth,
            canChiYear: canChiYear,
            zodiac: zodiac,
            solarTerm: solarTerm,
            currentHourCanChi: currentHourCanChi,
            dayElement: dayElement,
            oppositeZodiac: oppositeZodiac,
            tamHopGroup: tamHopGroup,
            hourPeriods: hourPeriods,
            dayGuidance: dayGuidance,
            dayOfficer: dayOfficer,
            nextAuspiciousHour: nextAuspiciousHour
        )
    }

    func weekdayName(from weekday: Int?) -> String {
        guard let weekday, (1 ... Self.weekdayNames.count).contains(weekday) else {
            return Self.weekdayNames[0]
        }
        return Self.weekdayNames[weekday - 1]
    }

    func weekdayShortName(from weekday: Int?) -> String {
        guard let weekday, (1 ... Self.weekdayShortNames.count).contains(weekday) else {
            return Self.weekdayShortNames[0]
        }
        return Self.weekdayShortNames[weekday - 1]
    }

    func weekdayNumberString(from weekday: Int?, style: WeekdayNumericStyle = .oneToSeven) -> String {
        style.value(from: weekday)
    }

    func weekdayName(from weekday: Int?, style: WeekdayDisplayStyle) -> String {
        style.weekdayName(from: weekday)
    }

    func weekdayShortName(from weekday: Int?, style: WeekdayDisplayStyle) -> String {
        style.weekdayShortName(from: weekday)
    }

    private func hourInterval(for branchIndex: Int, on dayDate: Date) -> DateInterval? {
        let dayStart = vietnamCalendar.startOfDay(for: dayDate)

        if branchIndex == 0 {
            guard
                let start = vietnamCalendar.date(byAdding: .hour, value: -1, to: dayStart),
                let end = vietnamCalendar.date(byAdding: .hour, value: 1, to: dayStart)
            else {
                return nil
            }
            return DateInterval(start: start, end: end)
        }

        let startOffsetHours = branchIndex * 2 - 1
        guard
            let start = vietnamCalendar.date(byAdding: .hour, value: startOffsetHours, to: dayStart),
            let end = vietnamCalendar.date(byAdding: .hour, value: 2, to: start)
        else {
            return nil
        }

        return DateInterval(start: start, end: end)
    }
}
