//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation
import WidgetKit

struct WidgetLunarInfo {
    let weekday: String
    let solarDate: String
    let lunarDay: String
    let lunarMonthText: String
    let lunarMonthYear: String
    let canChiDay: String
    let solarTerm: String
    let canChiYear: String
    let phaseIcon: String
    let zodiac: String

    static let placeholder = WidgetLunarInfo(
        weekday: "THỨ HAI",
        solarDate: "16/02/2026",
        lunarDay: "29",
        lunarMonthText: "Tháng 12",
        lunarMonthYear: "Tháng 12 năm Ất Tỵ",
        canChiDay: "Canh Thân",
        solarTerm: "Lập Xuân",
        canChiYear: "Ất Tỵ",
        phaseIcon: "moonphase.waxing.crescent",
        zodiac: "Rắn"
    )

    var accessibilitySummary: String {
        "Ngày âm \(lunarDay), \(lunarMonthYear), \(canChiDay), dương lịch \(solarDate)"
    }
}

struct LunarEntry: TimelineEntry {
    let date: Date
    let info: WidgetLunarInfo
}
