//
//  LunarV - Lich Am Viet Nam
//  Phat trien boi Pham Hung Tien
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

        return VietnameseLunarSnapshot(
            solar: solar,
            lunar: lunar,
            canChiDay: canChiDay,
            canChiMonth: canChiMonth,
            canChiYear: canChiYear,
            zodiac: zodiac,
            solarTerm: solarTerm,
            currentHourCanChi: currentHourCanChi
        )
    }

    func weekdayName(from weekday: Int?) -> String {
        guard let weekday, (1 ... Self.weekdayNames.count).contains(weekday) else {
            return Self.weekdayNames[0]
        }
        return Self.weekdayNames[weekday - 1]
    }
}
