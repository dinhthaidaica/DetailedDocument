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
}
