//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

enum VietnameseActivityCategory: String, CaseIterable, Hashable, Identifiable {
    case work = "Công việc"
    case finance = "Tài chính"
    case study = "Học tập"
    case travel = "Di chuyển"
    case family = "Gia đạo"

    var id: String { rawValue }
}

enum VietnameseGuidanceLevel: String, Hashable {
    case favorable
    case neutral
    case caution
}

enum VietnameseDayRating: String, Hashable {
    case excellent
    case positive
    case balanced
    case caution

    var title: String {
        switch self {
        case .excellent:
            return "Rất tốt"
        case .positive:
            return "Khá tốt"
        case .balanced:
            return "Cân bằng"
        case .caution:
            return "Nên thận trọng"
        }
    }
}

struct VietnameseActivityInsight: Hashable, Identifiable {
    let category: VietnameseActivityCategory
    let level: VietnameseGuidanceLevel
    let reason: String

    var id: VietnameseActivityCategory { category }
}

struct VietnameseDayGuidance: Hashable {
    let title: String
    let summary: String
    let score: Int
    let rating: VietnameseDayRating
    let recommendedActivities: [String]
    let avoidActivities: [String]
    let activityInsights: [VietnameseActivityInsight]
}

struct VietnameseAuspiciousHourWindow: Hashable {
    let period: VietnameseHourPeriod
    let startDate: Date
    let endDate: Date
}
