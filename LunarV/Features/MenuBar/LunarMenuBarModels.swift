//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

enum LunarGuidanceLevelInfo: Hashable {
    case favorable
    case neutral
    case caution
}

struct LunarActivityInsightInfo: Identifiable {
    let id = UUID()
    let categoryText: String
    let level: LunarGuidanceLevelInfo
    let reason: String
}

struct LunarDayOfficerInfo {
    let name: String
    let level: LunarGuidanceLevelInfo
    let summary: String
    let calculationNote: String
    let recommendedActivities: [String]
    let avoidActivities: [String]

    static let placeholder = LunarDayOfficerInfo(
        name: "--",
        level: .neutral,
        summary: "--",
        calculationNote: "--",
        recommendedActivities: [],
        avoidActivities: []
    )
}

struct LunarDayGuidanceInfo {
    let title: String
    let summary: String
    let score: Int
    let ratingText: String
    let recommendedActivities: [String]
    let avoidActivities: [String]
    let activityInsights: [LunarActivityInsightInfo]

    static let placeholder = LunarDayGuidanceInfo(
        title: "--",
        summary: "--",
        score: 0,
        ratingText: "--",
        recommendedActivities: [],
        avoidActivities: [],
        activityInsights: []
    )
}

struct LunarMonthDayCell: Identifiable {
    let id: Int
    let solarDay: Int?
    let lunarDay: Int?
    let isToday: Bool
    let isFirstLunarDay: Bool
    let holiday: String?
}

struct LunarHoliday: Identifiable {
    let id = UUID()
    let name: String
    let dateText: String
    let isLunar: Bool
    let daysUntil: Int
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
    let dayElementText: String
    let oppositeZodiacText: String
    let tamHopGroupText: String
    let nextAuspiciousHourText: String
    let auspiciousHours: [VietnameseHourPeriod]
    let inauspiciousHours: [VietnameseHourPeriod]
    let dayGuidance: LunarDayGuidanceInfo
    let dayOfficer: LunarDayOfficerInfo
    let weekOfYearText: String
    let dayOfYearText: String
    let monthTitleText: String
    let monthCells: [LunarMonthDayCell]
    
    let lunarPhaseIcon: String
    let lunarPhaseName: String
    let upcomingHolidays: [LunarHoliday]

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
        dayElementText: "--",
        oppositeZodiacText: "--",
        tamHopGroupText: "--",
        nextAuspiciousHourText: "--",
        auspiciousHours: [],
        inauspiciousHours: [],
        dayGuidance: .placeholder,
        dayOfficer: .placeholder,
        weekOfYearText: "--",
        dayOfYearText: "--",
        monthTitleText: "--",
        monthCells: [],
        lunarPhaseIcon: "moon.fill",
        lunarPhaseName: "--",
        upcomingHolidays: []
    )
}

enum HolidayProvider {
    static func solarHoliday(day: Int, month: Int) -> String? {
        switch (day, month) {
        case (1, 1): return "Tết Dương lịch"
        case (14, 2): return "Valentine"
        case (8, 3): return "Quốc tế Phụ nữ"
        case (26, 3): return "Ngày Thành lập Đoàn"
        case (30, 4): return "Giải phóng miền Nam"
        case (1, 5): return "Quốc tế Lao động"
        case (19, 5): return "Ngày sinh Bác Hồ"
        case (1, 6): return "Quốc tế Thiếu nhi"
        case (27, 7): return "Ngày Thương binh Liệt sĩ"
        case (19, 8): return "Ngày Cách mạng tháng Tám"
        case (2, 9): return "Quốc khánh"
        case (10, 10): return "Giải phóng Thủ đô"
        case (20, 10): return "Ngày Phụ nữ Việt Nam"
        case (20, 11): return "Ngày Nhà giáo Việt Nam"
        case (22, 12): return "Ngày Thành lập Quân đội"
        case (25, 12): return "Giáng sinh"
        default: return nil
        }
    }

    static func lunarHoliday(day: Int, month: Int) -> String? {
        switch (day, month) {
        case (1, 1): return "Mùng 1 Tết"
        case (2, 1): return "Mùng 2 Tết"
        case (3, 1): return "Mùng 3 Tết"
        case (15, 1): return "Rằm tháng Giêng"
        case (10, 3): return "Giỗ tổ Hùng Vương"
        case (15, 4): return "Lễ Phật Đản"
        case (5, 5): return "Tết Đoan Ngọ"
        case (15, 7): return "Lễ Vu Lan"
        case (15, 8): return "Tết Trung Thu"
        case (23, 12): return "Ông Táo chầu trời"
        case (30, 12): return "Giao thừa"
        case (29, 12): return "29 Tết"
        default: return nil
        }
    }
}
