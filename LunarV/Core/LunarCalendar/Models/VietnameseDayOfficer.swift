//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

struct VietnameseDayOfficer: Hashable {
    let name: String
    let level: VietnameseGuidanceLevel
    let summary: String
    let calculationNote: String
    let recommendedActivities: [String]
    let avoidActivities: [String]
}
