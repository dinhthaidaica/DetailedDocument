//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

struct VietnameseDayGuidance: Hashable {
    let title: String
    let summary: String
    let recommendedActivities: [String]
    let avoidActivities: [String]
}

struct VietnameseAuspiciousHourWindow: Hashable {
    let period: VietnameseHourPeriod
    let startDate: Date
    let endDate: Date
}
