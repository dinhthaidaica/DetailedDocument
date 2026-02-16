//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

enum MenuBarDisplayPreset: String, CaseIterable, Identifiable {
    case compact
    case standard
    case detailed
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact:
            return "Gọn"
        case .standard:
            return "Tiêu chuẩn"
        case .detailed:
            return "Chi tiết"
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
        case .detailed:
            return "Ưu tiên nhiều thông tin hơn"
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
        case .detailed:
            return "{dd}/{mm} {al} • {cy} • {z}"
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
}

enum MenuBarTitleFormatter {
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
        return render(template: template, context: context)
    }

    static func render(template: String, context: MenuBarTitleContext) -> String {
        var result = template

        let tokens: [(String, String)] = [
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

    private static func twoDigits(_ value: Int) -> String {
        String(format: "%02d", value)
    }
}
