//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

enum MenuBarDisplayPreset: String, CaseIterable, Identifiable {
    case compact
    case standard
    case canChiZodiac
    case weekdayTime
    case solarLunar
    case detailed
    case full
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact:
            return "Gọn"
        case .standard:
            return "Tiêu chuẩn"
        case .canChiZodiac:
            return "Can Chi + Giáp"
        case .weekdayTime:
            return "Thứ + giờ"
        case .solarLunar:
            return "Dương + Âm"
        case .detailed:
            return "Chi tiết"
        case .full:
            return "Toàn diện"
        case .custom:
            return "Tùy chỉnh"
        }
    }

    var subtitle: String {
        switch self {
        case .compact:
            return "Hiển thị ngắn gọn, tiết kiệm không gian"
        case .standard:
            return "Cân bằng giữa ngắn gọn và thông tin"
        case .canChiZodiac:
            return "Nhấn mạnh năm Can Chi và con giáp"
        case .weekdayTime:
            return "Thêm thứ và giờ/phút (không hiển thị giây)"
        case .solarLunar:
            return "Hiển thị đồng thời ngày dương và âm"
        case .detailed:
            return "Ưu tiên nhiều thông tin hơn (thứ + thời gian)"
        case .full:
            return "Hiển thị đầy đủ thứ, dương lịch, âm lịch và thời gian"
        case .custom:
            return "Tự định nghĩa bằng template token"
        }
    }

    var defaultTemplate: String {
        switch self {
        case .compact:
            return "{dd}/{mm} {al}"
        case .standard:
            return "{dd}/{mm} {al} {cy}"
        case .canChiZodiac:
            return "{dd}/{mm} {al} • {cy} • {z}"
        case .weekdayTime:
            return "{wds} • {dd}/{mm} {al} • {hh}:{min}"
        case .solarLunar:
            return "{sdd}/{smm} • {dd}/{mm} {al}"
        case .detailed:
            return "{dd}/{mm} {al} • {cy} • {wds} • {hh}:{min}:{ss}"
        case .full:
            return "{wd} • {sdd}/{smm}/{sy} • {dd}/{mm} {al} • {cy} • {hh}:{min}:{ss}"
        case .custom:
            return "{dd}/{mm} {al}"
        }
    }
}

struct MenuBarTitleContext {
    let lunarDay: Int
    let lunarMonth: Int
    let lunarYear: Int
    let isLeapMonth: Bool
    let canChiYear: String
    let zodiac: String
    let solarDay: Int
    let solarMonth: Int
    let solarYear: Int
    let solarWeekdayName: String
    let solarWeekdayShortName: String
    let solarWeekdayNumeric: String
    let solarWeekdayNumericTwoToEight: String
    let hour: Int
    let minute: Int
    let second: Int
}

enum MenuBarTitleFormatter {
    private enum TimeValueMode {
        case live
        case widthProbe
    }

    static func resolvedTemplate(preset: MenuBarDisplayPreset, customTemplate: String) -> String {
        if preset == .custom {
            let trimmed = customTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? MenuBarDisplayPreset.custom.defaultTemplate : trimmed
        }

        return preset.defaultTemplate
    }

    static func render(
        preset: MenuBarDisplayPreset,
        customTemplate: String,
        context: MenuBarTitleContext
    ) -> String {
        let template = resolvedTemplate(preset: preset, customTemplate: customTemplate)
        return render(template: template, context: context, timeValueMode: .live)
    }

    static func renderForStableTimeWidth(
        preset: MenuBarDisplayPreset,
        customTemplate: String,
        context: MenuBarTitleContext
    ) -> String {
        let template = resolvedTemplate(preset: preset, customTemplate: customTemplate)
        return render(template: template, context: context, timeValueMode: .widthProbe)
    }

    static func render(template: String, context: MenuBarTitleContext) -> String {
        render(template: template, context: context, timeValueMode: .live)
    }

    /// Xác định tần suất refresh phù hợp dựa trên template đang dùng
    static func refreshGranularity(preset: MenuBarDisplayPreset, customTemplate: String) -> RefreshGranularity {
        let template = resolvedTemplate(preset: preset, customTemplate: customTemplate)
        if template.contains("{ss}") || template.contains("{time}") || template.contains("{time12}") || template.contains("{:}") {
            return .everySecond
        }
        if
            template.contains("{hh}") ||
            template.contains("{min}") ||
            template.contains("{hh12}") ||
            template.contains("{h12}") ||
            template.contains("{time12m}") ||
            template.contains("{ampm}") ||
            template.contains("{ampml}") ||
            template.contains("{ampmvn}") ||
            template.contains("{ap}")
        {
            return .everyMinute
        }
        return .daily
    }

    enum RefreshGranularity {
        case everySecond
        case everyMinute
        case daily
    }

    private static func render(
        template: String,
        context: MenuBarTitleContext,
        timeValueMode: TimeValueMode
    ) -> String {
        var result = template

        let tokens: [(String, String)] = [
            ("{wds}", context.solarWeekdayShortName),
            ("{wd}", context.solarWeekdayName),
            ("{wdn}", context.solarWeekdayNumeric),
            ("{wdn2}", context.solarWeekdayNumericTwoToEight),
            ("{:}", blinkingColon(second: context.second, mode: timeValueMode)),
            ("{h12}", oneOrTwoDigitsTwelveHour(context.hour, mode: timeValueMode)),
            ("{hh12}", twoDigitsTwelveHour(context.hour, mode: timeValueMode)),
            ("{ampm}", ampmUppercase(from: context.hour)),
            ("{ampml}", ampmLowercase(from: context.hour)),
            ("{ampmvn}", ampmVietnameseAbbrev(from: context.hour)),
            ("{ap}", ampmInitial(from: context.hour)),
            ("{time12}", "\(twoDigitsTwelveHour(context.hour, mode: timeValueMode)):\(twoDigits(context.minute, mode: timeValueMode)):\(twoDigits(context.second, mode: timeValueMode)) \(ampmUppercase(from: context.hour))"),
            ("{time12m}", "\(twoDigitsTwelveHour(context.hour, mode: timeValueMode)):\(twoDigits(context.minute, mode: timeValueMode)) \(ampmUppercase(from: context.hour))"),
            ("{time}", "\(twoDigits(context.hour, mode: timeValueMode)):\(twoDigits(context.minute, mode: timeValueMode)):\(twoDigits(context.second, mode: timeValueMode))"),
            ("{hh}", twoDigits(context.hour, mode: timeValueMode)),
            ("{min}", twoDigits(context.minute, mode: timeValueMode)),
            ("{ss}", twoDigits(context.second, mode: timeValueMode)),
            ("{yyyy}", "\(context.lunarYear)"),
            ("{dd}", twoDigits(context.lunarDay)),
            ("{mm}", twoDigits(context.lunarMonth)),
            ("{sdd}", twoDigits(context.solarDay)),
            ("{smm}", twoDigits(context.solarMonth)),
            ("{sy}", "\(context.solarYear)"),
            ("{d}", "\(context.lunarDay)"),
            ("{m}", "\(context.lunarMonth)"),
            ("{sd}", "\(context.solarDay)"),
            ("{sm}", "\(context.solarMonth)"),
            ("{cy}", context.canChiYear),
            ("{z}", context.zodiac),
            ("{al}", "ÂL"),
            ("{leap}", context.isLeapMonth ? "N" : ""),
        ]

        for (token, value) in tokens {
            result = result.replacingOccurrences(of: token, with: value)
        }

        result = result.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        result = result.trimmingCharacters(in: .whitespacesAndNewlines)

        return result.isEmpty ? "--" : result
    }

    private static func twoDigits(_ value: Int, mode: TimeValueMode) -> String {
        switch mode {
        case .live:
            return twoDigits(value)
        case .widthProbe:
            // "88" thường là cặp số rộng nhất với hầu hết font, giúp cố định bề ngang cho token thời gian.
            return "88"
        }
    }

    private static func blinkingColon(second: Int, mode: TimeValueMode) -> String {
        switch mode {
        case .live:
            return second.isMultiple(of: 2) ? ":" : " "
        case .widthProbe:
            return ":"
        }
    }

    private static func twoDigitsTwelveHour(_ hour24: Int, mode: TimeValueMode) -> String {
        switch mode {
        case .live:
            return twoDigits(twelveHour(from: hour24))
        case .widthProbe:
            return "88"
        }
    }

    private static func oneOrTwoDigitsTwelveHour(_ hour24: Int, mode: TimeValueMode) -> String {
        switch mode {
        case .live:
            return "\(twelveHour(from: hour24))"
        case .widthProbe:
            // Dự phòng bề ngang cho trường hợp giờ hai chữ số (10-12).
            return "88"
        }
    }

    private static func twelveHour(from hour24: Int) -> Int {
        let normalizedHour = ((hour24 % 24) + 24) % 24
        let hour = normalizedHour % 12
        return hour == 0 ? 12 : hour
    }

    private static func ampmUppercase(from hour24: Int) -> String {
        isMorning(hour24) ? "AM" : "PM"
    }

    private static func ampmLowercase(from hour24: Int) -> String {
        isMorning(hour24) ? "am" : "pm"
    }

    private static func ampmVietnameseAbbrev(from hour24: Int) -> String {
        isMorning(hour24) ? "SA" : "CH"
    }

    private static func ampmInitial(from hour24: Int) -> String {
        isMorning(hour24) ? "A" : "P"
    }

    private static func isMorning(_ hour24: Int) -> Bool {
        let normalizedHour = ((hour24 % 24) + 24) % 24
        return normalizedHour < 12
    }

    private static func twoDigits(_ value: Int) -> String {
        String(format: "%02d", value)
    }
}
