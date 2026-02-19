//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

enum InternationalTimeFormatter {
    static func utcOffsetText(for timeZone: TimeZone, at date: Date) -> String {
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

    static func utcOffsetText(for timeZoneIdentifier: String, at date: Date) -> String {
        guard let timeZone = TimeZone(identifier: timeZoneIdentifier) else {
            return "UTC?"
        }

        return utcOffsetText(for: timeZone, at: date)
    }

    static func relativeDayOffset(
        at date: Date,
        localCalendar: Calendar = .autoupdatingCurrent,
        targetTimeZone: TimeZone
    ) -> Int {
        guard
            let localDayIdentity = dayIdentityDate(for: date, using: localCalendar),
            let targetDayIdentity = dayIdentityDate(for: date, in: targetTimeZone)
        else {
            return 0
        }

        var comparisonCalendar = Calendar(identifier: .gregorian)
        comparisonCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return comparisonCalendar.dateComponents([.day], from: localDayIdentity, to: targetDayIdentity).day ?? 0
    }

    static func relativeDayText(for dayOffset: Int) -> String {
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

    static func relativeDayText(
        at date: Date,
        targetTimeZone: TimeZone,
        localCalendar: Calendar = .autoupdatingCurrent
    ) -> String {
        let dayOffset = relativeDayOffset(
            at: date,
            localCalendar: localCalendar,
            targetTimeZone: targetTimeZone
        )
        return relativeDayText(for: dayOffset)
    }

    private static func dayIdentityDate(for date: Date, in timeZone: TimeZone) -> Date? {
        var targetCalendar = Calendar(identifier: .gregorian)
        targetCalendar.timeZone = timeZone
        return dayIdentityDate(for: date, using: targetCalendar)
    }

    private static func dayIdentityDate(for date: Date, using calendar: Calendar) -> Date? {
        let dayComponents = calendar.dateComponents([.year, .month, .day], from: date)
        var comparisonCalendar = Calendar(identifier: .gregorian)
        comparisonCalendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return comparisonCalendar.date(from: dayComponents)
    }
}
