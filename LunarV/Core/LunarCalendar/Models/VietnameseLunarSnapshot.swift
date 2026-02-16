//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

struct VietnameseHourPeriod: Identifiable, Hashable {
    let branchIndex: Int
    let branch: String
    let canChi: String
    let timeRange: String
    let isAuspicious: Bool

    var id: Int { branchIndex }
}

struct VietnameseLunarSnapshot {
    let solar: SolarDateComponents
    let lunar: LunarDate
    let canChiDay: String
    let canChiMonth: String
    let canChiYear: String
    let zodiac: String
    let solarTerm: String
    let currentHourCanChi: String
    let dayElement: String
    let oppositeZodiac: String
    let tamHopGroup: String
    let hourPeriods: [VietnameseHourPeriod]
}
