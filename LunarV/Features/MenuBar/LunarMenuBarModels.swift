import Foundation

struct LunarMonthDayCell: Identifiable {
    let id: Int
    let solarDay: Int?
    let lunarDay: Int?
    let isToday: Bool
    let isFirstLunarDay: Bool
}

struct LunarMenuBarInfo {
    let weekdayText: String
    let solarDateText: String
    let lunarDateText: String
    let lunarDayText: String
    let lunarMonthYearText: String
    let leapMonthText: String?
    let canChiDayText: String
    let canChiMonthText: String
    let canChiYearText: String
    let solarTermText: String
    let zodiacText: String
    let currentHourCanChiText: String
    let weekOfYearText: String
    let dayOfYearText: String
    let monthTitleText: String
    let monthCells: [LunarMonthDayCell]

    static let placeholder = LunarMenuBarInfo(
        weekdayText: "--",
        solarDateText: "--/--/----",
        lunarDateText: "--/--",
        lunarDayText: "--",
        lunarMonthYearText: "--",
        leapMonthText: nil,
        canChiDayText: "--",
        canChiMonthText: "--",
        canChiYearText: "--",
        solarTermText: "--",
        zodiacText: "--",
        currentHourCanChiText: "--",
        weekOfYearText: "--",
        dayOfYearText: "--",
        monthTitleText: "--",
        monthCells: []
    )
}
