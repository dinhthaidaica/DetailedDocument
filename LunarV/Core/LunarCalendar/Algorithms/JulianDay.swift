//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

enum JulianDay {
    static func fromGregorian(day: Int, month: Int, year: Int) -> Int {
        let a = (14 - month) / 12
        let y = year + 4800 - a
        let m = month + 12 * a - 3

        var jd = day + ((153 * m + 2) / 5) + (365 * y) + (y / 4) - (y / 100) + (y / 400) - 32045
        if jd < 2_299_161 {
            jd = day + ((153 * m + 2) / 5) + (365 * y) + (y / 4) - 32083
        }
        return jd
    }

    static func sunLongitude(jdn: Double) -> Double {
        let t = (jdn - 2_451_545.0) / 36525
        let t2 = t * t
        let dr = Double.pi / 180
        let m = 357.52910 + 35999.05030 * t - 0.0001559 * t2 - 0.00000048 * t * t2
        let l0 = 280.46645 + 36000.76983 * t + 0.0003032 * t2

        var dl = (1.914600 - 0.004817 * t - 0.000014 * t2) * sin(dr * m)
        dl += (0.019993 - 0.000101 * t) * sin(2 * dr * m) + 0.000290 * sin(3 * dr * m)

        var longitude = l0 + dl
        longitude *= dr
        longitude -= Double.pi * 2 * floor(longitude / (Double.pi * 2))
        return longitude
    }
}
