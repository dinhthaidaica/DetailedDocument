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
    var id: String { categoryText }
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
    var id: String { "\(daysUntil)-\(isLunar ? "L" : "S")-\(name)" }
    let name: String
    let dateText: String
    let isLunar: Bool
    let daysUntil: Int
}

struct InternationalTimeInfo: Identifiable {
    let id: String
    let city: String
    let timeText: String
    let weekdayText: String
    let utcOffsetText: String
    let relativeDayText: String
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
    let internationalTimes: [InternationalTimeInfo]

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
        upcomingHolidays: [],
        internationalTimes: []
    )
}

enum HolidayProvider {
    static func solarHoliday(day: Int, month: Int) -> String? {
        switch (day, month) {
        // Tháng 1
        case (1, 1): return "Tết Dương lịch"
        // Tháng 2
        case (3, 2): return "Ngày Thành lập Đảng"
        case (14, 2): return "Valentine"
        case (27, 2): return "Ngày Thầy thuốc Việt Nam"
        // Tháng 3
        case (8, 3): return "Quốc tế Phụ nữ"
        case (26, 3): return "Ngày Thành lập Đoàn"
        // Tháng 4
        case (21, 4): return "Ngày Sách Việt Nam"
        case (30, 4): return "Giải phóng miền Nam"
        // Tháng 5
        case (1, 5): return "Quốc tế Lao động"
        case (7, 5): return "Chiến thắng Điện Biên Phủ"
        case (13, 5): return "Ngày Hiến chương Nhà báo"
        case (19, 5): return "Ngày sinh Bác Hồ"
        // Tháng 6
        case (1, 6): return "Quốc tế Thiếu nhi"
        case (21, 6): return "Ngày Báo chí Việt Nam"
        case (28, 6): return "Ngày Gia đình Việt Nam"
        // Tháng 7
        case (11, 7): return "Ngày Dân số Thế giới"
        case (27, 7): return "Ngày Thương binh Liệt sĩ"
        case (28, 7): return "Ngày thành lập Công đoàn"
        // Tháng 8
        case (19, 8): return "Ngày Cách mạng tháng Tám"
        // Tháng 9
        case (2, 9): return "Quốc khánh"
        case (7, 9): return "Ngày thành lập Đài Tiếng nói VN"
        // Tháng 10
        case (1, 10): return "Ngày Quốc tế Người cao tuổi"
        case (10, 10): return "Giải phóng Thủ đô"
        case (13, 10): return "Ngày Doanh nhân Việt Nam"
        case (15, 10): return "Ngày thành lập Hội LHPN"
        case (20, 10): return "Ngày Phụ nữ Việt Nam"
        case (31, 10): return "Halloween"
        // Tháng 11
        case (9, 11): return "Ngày Pháp luật Việt Nam"
        case (20, 11): return "Ngày Nhà giáo Việt Nam"
        case (23, 11): return "Ngày thành lập MTTQVN"
        // Tháng 12
        case (1, 12): return "Ngày Thế giới phòng chống AIDS"
        case (22, 12): return "Ngày Thành lập Quân đội"
        case (24, 12): return "Đêm Giáng sinh"
        case (25, 12): return "Giáng sinh"
        default: return nil
        }
    }

    static func lunarHoliday(day: Int, month: Int) -> String? {
        switch (day, month) {
        // Tháng Giêng
        case (1, 1): return "Mùng 1 Tết"
        case (2, 1): return "Mùng 2 Tết"
        case (3, 1): return "Mùng 3 Tết"
        case (4, 1): return "Mùng 4 Tết"
        case (5, 1): return "Mùng 5 Tết"
        case (9, 1): return "Ngày vía Trời (Ngọc Hoàng)"
        case (15, 1): return "Rằm tháng Giêng"
        // Tháng 2
        case (15, 2): return "Rằm tháng Hai"
        // Tháng 3
        case (3, 3): return "Tết Hàn Thực"
        case (10, 3): return "Giỗ tổ Hùng Vương"
        case (15, 3): return "Rằm tháng Ba"
        // Tháng 4
        case (15, 4): return "Lễ Phật Đản"
        // Tháng 5
        case (5, 5): return "Tết Đoan Ngọ"
        case (15, 5): return "Rằm tháng Năm"
        // Tháng 7
        case (15, 7): return "Lễ Vu Lan"
        // Tháng 8
        case (15, 8): return "Tết Trung Thu"
        // Tháng 9
        case (9, 9): return "Tết Trùng Cửu"
        // Tháng 10
        case (10, 10): return "Tết Trùng Thập"
        case (15, 10): return "Tết Hạ Nguyên"
        // Tháng 12
        case (8, 12): return "Lễ Phật Thành Đạo"
        case (23, 12): return "Ông Táo chầu trời"
        case (29, 12): return "29 Tết"
        case (30, 12): return "Giao thừa"
        default: return nil
        }
    }
}
