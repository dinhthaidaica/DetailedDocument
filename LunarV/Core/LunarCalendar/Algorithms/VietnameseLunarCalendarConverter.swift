//
//  LunarV - Lịch Âm Việt Nam
//  Phát triển bởi Phạm Hùng Tiến
//
import Foundation

protocol LunarDateConverting {
    func solarToLunar(day: Int, month: Int, year: Int) -> LunarDate
}

struct VietnameseLunarCalendarConverter: LunarDateConverting {
    private let timeZone: Double

    init(timeZone: Double = 7.0) {
        self.timeZone = timeZone
    }

    func solarToLunar(day: Int, month: Int, year: Int) -> LunarDate {
        Self.solarToLunar(day: day, month: month, year: year, timeZone: timeZone)
    }

    private static func solarToLunar(day: Int, month: Int, year: Int, timeZone: Double) -> LunarDate {
        let dayNumber = JulianDay.fromGregorian(day: day, month: month, year: year)
        let k = Int(floor((Double(dayNumber) - 2_415_021.076998695) / 29.530588853))
        var monthStart = getNewMoonDay(k: k + 1, timeZone: timeZone)
        if monthStart > dayNumber {
            monthStart = getNewMoonDay(k: k, timeZone: timeZone)
        }

        var a11 = getLunarMonth11(year: year, timeZone: timeZone)
        var b11 = a11
        var lunarYear: Int

        if a11 >= monthStart {
            lunarYear = year
            a11 = getLunarMonth11(year: year - 1, timeZone: timeZone)
        } else {
            lunarYear = year + 1
            b11 = getLunarMonth11(year: year + 1, timeZone: timeZone)
        }

        let lunarDay = dayNumber - monthStart + 1
        let diff = Int(floor(Double(monthStart - a11) / 29.0))
        var lunarLeap = false
        var lunarMonth = diff + 11

        if b11 - a11 > 365 {
            let leapMonthDiff = getLeapMonthOffset(a11: a11, timeZone: timeZone)
            if diff >= leapMonthDiff {
                lunarMonth = diff + 10
                if diff == leapMonthDiff {
                    lunarLeap = true
                }
            }
        }

        if lunarMonth > 12 {
            lunarMonth -= 12
        }
        if lunarMonth >= 11 && diff < 4 {
            lunarYear -= 1
        }

        return LunarDate(day: lunarDay, month: lunarMonth, year: lunarYear, isLeapMonth: lunarLeap)
    }

    private static func getNewMoonDay(k: Int, timeZone: Double) -> Int {
        let jd = newMoon(k: k)
        return Int(floor(jd + 0.5 + timeZone / 24.0))
    }

    private static func getSunLongitude(dayNumber: Int, timeZone: Double) -> Int {
        let longitude = sunLongitude(jdn: Double(dayNumber) - 0.5 - timeZone / 24.0)
        return Int(floor(longitude / Double.pi * 6.0))
    }

    private static func getLunarMonth11(year: Int, timeZone: Double) -> Int {
        let off = JulianDay.fromGregorian(day: 31, month: 12, year: year) - 2_415_021
        let k = Int(floor(Double(off) / 29.530588853))
        var month11 = getNewMoonDay(k: k, timeZone: timeZone)
        let sunLongitude = getSunLongitude(dayNumber: month11, timeZone: timeZone)
        if sunLongitude >= 9 {
            month11 = getNewMoonDay(k: k - 1, timeZone: timeZone)
        }
        return month11
    }

    private static func getLeapMonthOffset(a11: Int, timeZone: Double) -> Int {
        let k = Int(floor((Double(a11) - 2_415_021.076998695) / 29.530588853 + 0.5))
        var lastArc = 0
        var i = 1
        var arc = getSunLongitude(dayNumber: getNewMoonDay(k: k + i, timeZone: timeZone), timeZone: timeZone)

        repeat {
            lastArc = arc
            i += 1
            arc = getSunLongitude(dayNumber: getNewMoonDay(k: k + i, timeZone: timeZone), timeZone: timeZone)
        } while arc != lastArc && i < 14

        return i - 1
    }

    private static func newMoon(k: Int) -> Double {
        let t = Double(k) / 1236.85
        let t2 = t * t
        let t3 = t2 * t
        let dr = Double.pi / 180

        var jd1 = 2_415_020.75933 + 29.53058868 * Double(k) + 0.0001178 * t2 - 0.000000155 * t3
        jd1 += 0.00033 * sin((166.56 + 132.87 * t - 0.009173 * t2) * dr)

        let m = 359.2242 + 29.10535608 * Double(k) - 0.0000333 * t2 - 0.00000347 * t3
        let mPrime = 306.0253 + 385.81691806 * Double(k) + 0.0107306 * t2 + 0.00001236 * t3
        let f = 21.2964 + 390.67050646 * Double(k) - 0.0016528 * t2 - 0.00000239 * t3

        var c1 = (0.1734 - 0.000393 * t) * sin(m * dr) + 0.0021 * sin(2 * dr * m)
        c1 -= 0.4068 * sin(mPrime * dr) + 0.0161 * sin(2 * dr * mPrime)
        c1 -= 0.0004 * sin(3 * dr * mPrime)
        c1 += 0.0104 * sin(2 * dr * f) - 0.0051 * sin(dr * (m + mPrime))
        c1 -= 0.0074 * sin(dr * (m - mPrime)) + 0.0004 * sin(dr * (2 * f + m))
        c1 -= 0.0004 * sin(dr * (2 * f - m)) - 0.0006 * sin(dr * (2 * f + mPrime))
        c1 += 0.0010 * sin(dr * (2 * f - mPrime)) + 0.0005 * sin(dr * (2 * mPrime + m))

        let deltaT: Double
        if t < -11 {
            deltaT = 0.001 + 0.000839 * t + 0.0002261 * t2 - 0.00000845 * t3 - 0.000000081 * t * t3
        } else {
            deltaT = -0.000278 + 0.000265 * t + 0.000262 * t2
        }

        return jd1 + c1 - deltaT
    }

    private static func sunLongitude(jdn: Double) -> Double {
        JulianDay.sunLongitude(jdn: jdn)
    }
}
