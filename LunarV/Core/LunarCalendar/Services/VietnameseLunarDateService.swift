//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

struct VietnameseLunarDateService {
    static let defaultTimeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        ?? TimeZone(secondsFromGMT: 7 * 3600)
        ?? .current
    static let weekdayNames = ["Chủ Nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy"]

    let timeZone: TimeZone
    let calendar: Calendar
    private let lunarConverter: any LunarDateConverting

    init(
        timeZone: TimeZone = VietnameseLunarDateService.defaultTimeZone,
        calendar: Calendar = Calendar(identifier: .gregorian),
        lunarConverter: (any LunarDateConverting)? = nil
    ) {
        var configuredCalendar = calendar
        configuredCalendar.timeZone = timeZone
        configuredCalendar.locale = Locale(identifier: "vi_VN")
        configuredCalendar.firstWeekday = 2

        self.timeZone = timeZone
        self.calendar = configuredCalendar
        self.lunarConverter = lunarConverter ?? VietnameseLunarCalendarConverter(timeZone: 7.0)
    }

    func solarComponents(from date: Date) -> SolarDateComponents? {
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
        guard let solar = solarComponents(from: date) else {
            return nil
        }
        return lunarDate(day: solar.day, month: solar.month, year: solar.year)
    }

    func solarDate(from targetLunarDate: LunarDate, searchGregorianYears: ClosedRange<Int>? = nil) -> SolarDateComponents? {
        let searchRange = searchGregorianYears ?? (targetLunarDate.year - 1)...(targetLunarDate.year + 1)

        for year in searchRange {
            guard
                let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)),
                let months = calendar.range(of: .month, in: .year, for: startOfYear)
            else {
                continue
            }

            for month in months {
                guard
                    let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                    let days = calendar.range(of: .day, in: .month, for: monthStart)
                else {
                    continue
                }

                for day in days {
                    let resolvedLunarDate = lunarDate(day: day, month: month, year: year)
                    guard resolvedLunarDate == targetLunarDate else {
                        continue
                    }

                    guard let candidateDate = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
                        continue
                    }

                    return solarComponents(from: candidateDate)
                }
            }
        }

        return nil
    }

    func nextAuspiciousHour(from date: Date, lookAheadDays: Int = 2) -> VietnameseAuspiciousHourWindow? {
        let boundedLookAheadDays = max(lookAheadDays, 0)
        let dayStart = calendar.startOfDay(for: date)

        for dayOffset in 0 ... boundedLookAheadDays {
            guard
                let targetDay = calendar.date(byAdding: .day, value: dayOffset, to: dayStart),
                let solar = solarComponents(from: targetDay)
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
        guard let solar = solarComponents(from: date) else {
            return nil
        }

        let lunar = lunarDate(day: solar.day, month: solar.month, year: solar.year)
        let canChiDay = VietnameseCalendarMetadata.canChiDay(day: solar.day, month: solar.month, year: solar.year)
        let canChiMonth = VietnameseCalendarMetadata.canChiMonth(lunarMonth: lunar.month, lunarYear: lunar.year)
        let canChiYear = VietnameseCalendarMetadata.canChiYear(lunarYear: lunar.year)
        let zodiac = VietnameseCalendarMetadata.zodiac(lunarYear: lunar.year)
        let solarTerm = VietnameseCalendarMetadata.solarTerm(date: date, timeZone: timeZone)
        let currentHourCanChi = VietnameseCalendarMetadata.canChiHour(
            date: date,
            day: solar.day,
            month: solar.month,
            year: solar.year,
            calendar: calendar
        )
        let dayElement = VietnameseCalendarMetadata.dayElement(day: solar.day, month: solar.month, year: solar.year)
        let oppositeZodiac = VietnameseCalendarMetadata.oppositeZodiac(day: solar.day, month: solar.month, year: solar.year)
        let tamHopGroup = VietnameseCalendarMetadata.tamHopGroup(day: solar.day, month: solar.month, year: solar.year)
        let hourPeriods = VietnameseCalendarMetadata.hourPeriods(day: solar.day, month: solar.month, year: solar.year)
        let dayGuidance = VietnameseDayGuidanceProvider.guidance(dayElement: dayElement, solarTerm: solarTerm)
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
            nextAuspiciousHour: nextAuspiciousHour
        )
    }

    func weekdayName(from weekday: Int?) -> String {
        guard let weekday, (1 ... Self.weekdayNames.count).contains(weekday) else {
            return Self.weekdayNames[0]
        }
        return Self.weekdayNames[weekday - 1]
    }

    private func hourInterval(for branchIndex: Int, on dayDate: Date) -> DateInterval? {
        let dayStart = calendar.startOfDay(for: dayDate)

        if branchIndex == 0 {
            guard
                let start = calendar.date(byAdding: .hour, value: -1, to: dayStart),
                let end = calendar.date(byAdding: .hour, value: 1, to: dayStart)
            else {
                return nil
            }
            return DateInterval(start: start, end: end)
        }

        let startOffsetHours = branchIndex * 2 - 1
        guard
            let start = calendar.date(byAdding: .hour, value: startOffsetHours, to: dayStart),
            let end = calendar.date(byAdding: .hour, value: 2, to: start)
        else {
            return nil
        }

        return DateInterval(start: start, end: end)
    }
}
