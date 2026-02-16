//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

struct SolarDateComponents: Equatable {
    let day: Int
    let month: Int
    let year: Int
    let weekday: Int?
    let weekOfYear: Int?
    let dayOfYear: Int?

    var formattedDate: String {
        String(format: "%02d/%02d/%04d", day, month, year)
    }
}
