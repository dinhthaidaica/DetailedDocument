//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

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

    func solarDate(from targetLunarDate: LunarDate, searchGregorianYears: ClosedRange<Int>? = nil) -> SolarDateComponents? {
        let searchRange = searchGregorianYears ?? (targetLunarDate.year - 1)...(targetLunarDate.year + 1)

        for year in searchRange {
            guard
                let startOfYear = vietnamCalendar.date(from: DateComponents(year: year, month: 1, day: 1)),
                let months = vietnamCalendar.range(of: .month, in: .year, for: startOfYear)
            else {
                continue
            }

            for month in months {
                guard
                    let monthStart = vietnamCalendar.date(from: DateComponents(year: year, month: month, day: 1)),
                    let days = vietnamCalendar.range(of: .day, in: .month, for: monthStart)
                else {
                    continue
                }

                for day in days {
                    let resolvedLunarDate = lunarDate(day: day, month: month, year: year)
                    guard resolvedLunarDate == targetLunarDate else {
                        continue
                    }

                    guard let candidateDate = vietnamCalendar.date(from: DateComponents(year: year, month: month, day: day)) else {
                        continue
                    }

                    return solarComponents(from: candidateDate, using: vietnamCalendar)
                }
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
